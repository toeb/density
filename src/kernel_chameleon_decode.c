/*
 * Centaurean Density
 * http://www.libssc.net
 *
 * Copyright (c) 2013, Guillaume Voirin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Centaurean nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * 24/10/13 12:28
 *
 * -------------------
 * Chameleon algorithm
 * -------------------
 *
 * Author(s)
 * Guillaume Voirin (https://github.com/gpnuma)
 *
 * Description
 * Hash based superfast kernel
 */

#include "kernel_chameleon_decode.h"

DENSITY_FORCE_INLINE DENSITY_KERNEL_DECODE_STATE density_chameleon_decode_check_state(density_memory_location *restrict out, density_chameleon_decode_state *restrict state) {
    if (out->available_bytes < DENSITY_CHAMELEON_DECODE_MINIMUM_OUTPUT_LOOKAHEAD)
        return DENSITY_KERNEL_DECODE_STATE_STALL_ON_OUTPUT_BUFFER;

    switch (state->signaturesCount) {
        case DENSITY_CHAMELEON_PREFERRED_EFFICIENCY_CHECK_SIGNATURES:
            if (state->efficiencyChecked ^ 0x1) {
                state->efficiencyChecked = 1;
                return DENSITY_KERNEL_DECODE_STATE_INFO_EFFICIENCY_CHECK;
            }
            break;
        case DENSITY_CHAMELEON_PREFERRED_BLOCK_SIGNATURES:
            state->signaturesCount = 0;
            state->efficiencyChecked = 0;

            if (state->resetCycle)
                state->resetCycle--;
            else {
                density_byte resetDictionaryCycleShift = state->parameters.as_bytes[0];
                if (resetDictionaryCycleShift) {
                    density_chameleon_dictionary_reset(&state->dictionary);
                    state->resetCycle = (uint_fast64_t) (1 << resetDictionaryCycleShift) - 1;
                }
            }

            return DENSITY_KERNEL_DECODE_STATE_INFO_NEW_BLOCK;
        default:
            break;
    }
    return DENSITY_KERNEL_DECODE_STATE_READY;
}

DENSITY_FORCE_INLINE void density_chameleon_decode_read_signature(density_memory_location *restrict in, density_chameleon_decode_state *restrict state) {
    state->signature = DENSITY_LITTLE_ENDIAN_64(*(density_chameleon_signature *) (in->pointer));
    in->pointer += sizeof(density_chameleon_signature);
    in->available_bytes -= sizeof(density_chameleon_signature);
    state->shift = 0;
    state->signaturesCount++;
}

DENSITY_FORCE_INLINE void density_chameleon_decode_read_compressed_chunk(uint16_t *chunk, density_memory_location *restrict in) {
    *chunk = *(uint16_t *) (in->pointer);
    in->pointer += sizeof(uint16_t);
    in->available_bytes -= sizeof(uint16_t);
}

DENSITY_FORCE_INLINE void density_chameleon_decode_read_uncompressed_chunk(uint32_t *chunk, density_memory_location *restrict in) {
    *chunk = *(uint32_t *) (in->pointer);
    in->pointer += sizeof(uint32_t);
    in->available_bytes -= sizeof(uint32_t);
}

DENSITY_FORCE_INLINE void density_chameleon_decode_compressed_chunk(const uint16_t *chunk, density_memory_location *restrict out, density_chameleon_decode_state *restrict state) {
    *(uint32_t *) (out->pointer) = (&state->dictionary.entries[DENSITY_LITTLE_ENDIAN_16(*chunk)])->as_uint32_t;
    out->pointer += sizeof(uint32_t);
    out->available_bytes -= sizeof(uint32_t);
}

DENSITY_FORCE_INLINE void density_chameleon_decode_uncompressed_chunk(const uint32_t *chunk, density_memory_location *restrict out, density_chameleon_decode_state *restrict state) {
    uint32_t hash;
    DENSITY_CHAMELEON_HASH_ALGORITHM(hash, DENSITY_LITTLE_ENDIAN_32(*chunk));
    (&state->dictionary.entries[hash])->as_uint32_t = *chunk;
    *(uint32_t *) (out->pointer) = *chunk;
    out->pointer += sizeof(uint32_t);
    out->available_bytes -= sizeof(uint32_t);
}

DENSITY_FORCE_INLINE void density_chameleon_decode_kernel(density_memory_location *restrict in, density_memory_location *restrict out, const density_bool compressed, density_chameleon_decode_state *restrict state) {
    if (compressed) {
        uint16_t chunk;
        density_chameleon_decode_read_compressed_chunk(&chunk, in);
        density_chameleon_decode_compressed_chunk(&chunk, out, state);
    } else {
        uint32_t chunk;
        density_chameleon_decode_read_uncompressed_chunk(&chunk, in);
        density_chameleon_decode_uncompressed_chunk(&chunk, out, state);
    }
}

DENSITY_FORCE_INLINE const bool density_chameleon_decode_test_compressed(density_chameleon_decode_state *state) {
    return (density_bool const) ((state->signature >> state->shift) & DENSITY_CHAMELEON_SIGNATURE_FLAG_MAP);
}

DENSITY_FORCE_INLINE void density_chameleon_decode_process_data(density_memory_location *restrict in, density_memory_location *restrict out, density_chameleon_decode_state *restrict state) {
    while (state->shift ^ 64) {
        density_chameleon_decode_kernel(in, out, density_chameleon_decode_test_compressed(state), state);
        state->shift++;
    }
}

DENSITY_FORCE_INLINE density_bool density_chameleon_decode_attempt_copy(density_memory_location *restrict out, density_byte *restrict origin, const uint_fast32_t count) {
    if (count <= out->available_bytes) {
        memcpy(out->pointer, origin, count);
        out->pointer += count;
        out->available_bytes -= count;
        return false;
    }
    return true;
}

DENSITY_FORCE_INLINE DENSITY_KERNEL_DECODE_STATE density_chameleon_decode_init(density_chameleon_decode_state *restrict state, const density_main_header_parameters parameters, const uint_fast32_t endDataOverhead) {
    state->signaturesCount = 0;
    state->efficiencyChecked = 0;
    density_chameleon_dictionary_reset(&state->dictionary);

    state->partialInput.pointer = state->partialInputBuffer;
    state->partialInput.available_bytes = 0;

    state->parameters = parameters;
    density_byte resetDictionaryCycleShift = state->parameters.as_bytes[0];
    if (resetDictionaryCycleShift)
        state->resetCycle = (uint_fast64_t) (1 << resetDictionaryCycleShift) - 1;

    state->endDataOverhead = endDataOverhead;

    state->process = DENSITY_CHAMELEON_DECODE_PROCESS_CONTINUE;

    return DENSITY_KERNEL_DECODE_STATE_READY;
}

DENSITY_FORCE_INLINE DENSITY_KERNEL_DECODE_STATE density_chameleon_decode_process(density_memory_location *restrict in, density_memory_location *restrict out, density_chameleon_decode_state *restrict state, const density_bool flush) {
    DENSITY_KERNEL_DECODE_STATE returnState;
    uint_fast64_t limit;

    switch (state->process) {
        case DENSITY_CHAMELEON_DECODE_PROCESS_CONTINUE:
            if (state->partialInput.available_bytes) {
                uint_fast64_t missingBytes = DENSITY_CHAMELEON_DECODE_PROCESS_UNIT_SIZE - state->partialInput.available_bytes;
                if (in->available_bytes > missingBytes) {
                    memcpy(state->partialInput.pointer + state->partialInput.available_bytes, in->pointer, missingBytes);

                    state->partialInput.available_bytes = DENSITY_CHAMELEON_DECODE_PROCESS_UNIT_SIZE;

                    in->pointer += missingBytes;
                    in->available_bytes -= missingBytes;

                    if ((returnState = density_chameleon_decode_check_state(out, state)))
                        return returnState;
                    density_chameleon_decode_read_signature(&state->partialInput, state);
                    density_chameleon_decode_process_data(&state->partialInput, out, state);

                    state->partialInput.pointer = state->partialInputBuffer;
                    state->partialInput.available_bytes = 0;
                    goto zero_bytes_accumulated;
                } else {
                    accumulate_remaining_bytes:
                    if (in->available_bytes) {
                        memcpy(state->partialInput.pointer + state->partialInput.available_bytes, in->pointer, in->available_bytes);
                        state->partialInput.available_bytes += in->available_bytes;

                        in->pointer += in->available_bytes;
                        in->available_bytes = 0;
                    }

                    if (flush) {
                        state->process = DENSITY_CHAMELEON_DECODE_PROCESS_FLUSH;
                        goto flush_accumulated_data;
                    } else
                        return DENSITY_KERNEL_DECODE_STATE_STALL_ON_INPUT_BUFFER;
                }
            } else {
                zero_bytes_accumulated:
                limit = in->available_bytes % DENSITY_CHAMELEON_DECODE_PROCESS_UNIT_SIZE;
                while (in->available_bytes != limit) {
                    if ((returnState = density_chameleon_decode_check_state(out, state)))
                        return returnState;
                    density_chameleon_decode_read_signature(in, state);
                    density_chameleon_decode_process_data(in, out, state);
                }
                goto accumulate_remaining_bytes;
            }

        case DENSITY_CHAMELEON_DECODE_PROCESS_FLUSH:
        flush_accumulated_data:
            if (state->partialInput.available_bytes > sizeof(density_chameleon_signature)) {
                if ((returnState = density_chameleon_decode_check_state(out, state)))
                    return returnState;
                density_chameleon_decode_read_signature(&state->partialInput, state);
                while (state->shift ^ 64) {
                    if (state->partialInput.available_bytes < sizeof(uint32_t))
                        goto exit;
                    else {
                        density_chameleon_decode_kernel(&state->partialInput, out, density_chameleon_decode_test_compressed(state), state);
                        state->shift++;
                    }
                }
            }
        exit:
            if (state->partialInput.available_bytes > 0) {
                if (density_chameleon_decode_attempt_copy(out, state->partialInput.pointer, (uint32_t) state->partialInput.available_bytes))
                    return DENSITY_KERNEL_DECODE_STATE_STALL_ON_OUTPUT_BUFFER;
            }
            state->partialInput.available_bytes = 0;
            state->process = DENSITY_CHAMELEON_DECODE_PROCESS_CONTINUE;
            return DENSITY_KERNEL_DECODE_STATE_FINISHED;
    }
}

DENSITY_FORCE_INLINE DENSITY_KERNEL_DECODE_STATE density_chameleon_decode_finish(density_chameleon_decode_state *state) {
    return DENSITY_KERNEL_DECODE_STATE_READY;
}
