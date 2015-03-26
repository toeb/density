/*
 * Centaurean Density
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
 * 24/10/13 12:01
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

#include "kernel_chameleon_encode.h"

DENSITY_REQUIRED_INLINE DENSITY_KERNEL_ENCODE_STATE exitProcess(density_chameleon_encode_state *state, DENSITY_CHAMELEON_ENCODE_PROCESS process, DENSITY_KERNEL_ENCODE_STATE kernelEncodeState) {
    state->process = process;
    return kernelEncodeState;
}

DENSITY_FORCE_INLINE void density_chameleon_encode_write_to_signature(density_chameleon_encode_state *state) {
#if __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
    (state->proximitySignature) |= ((uint64_t) DENSITY_CHAMELEON_SIGNATURE_FLAG_MAP) << state->shift;
#elif __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
    (state->proximitySignature) |= ((uint64_t) DENSITY_CHAMELEON_SIGNATURE_FLAG_MAP) << ((56 - (state->shift & ~0x7)) + (state->shift & 0x7));
#endif
}

DENSITY_FORCE_INLINE void density_chameleon_encode_prepare_new_signature(density_memory_location *restrict out, density_chameleon_encode_state *restrict state) {
    state->signaturesCount++;
    state->shift = 0;
    state->signature = (density_chameleon_signature *) (out->pointer);
    state->proximitySignature = 0;

    out->pointer += sizeof(density_chameleon_signature);
    out->available_bytes -= sizeof(density_chameleon_signature);
}

DENSITY_FORCE_INLINE DENSITY_KERNEL_ENCODE_STATE density_chameleon_encode_prepare_new_block(density_memory_location *restrict out, density_chameleon_encode_state *restrict state) {
    if (DENSITY_CHAMELEON_MAXIMUM_COMPRESSED_UNIT_SIZE > out->available_bytes)
        return DENSITY_KERNEL_ENCODE_STATE_STALL_ON_OUTPUT;

    switch (state->signaturesCount) {
        case DENSITY_CHAMELEON_PREFERRED_EFFICIENCY_CHECK_SIGNATURES:
            if (state->efficiencyChecked ^ 0x1) {
                state->efficiencyChecked = 1;
                return DENSITY_KERNEL_ENCODE_STATE_INFO_EFFICIENCY_CHECK;
            }
            break;
        case DENSITY_CHAMELEON_PREFERRED_BLOCK_SIGNATURES:
            state->signaturesCount = 0;
            state->efficiencyChecked = 0;

#if DENSITY_ENABLE_PARALLELIZABLE_DECOMPRESSIBLE_OUTPUT == DENSITY_YES
            if (state->resetCycle)
                state->resetCycle--;
            else {
                density_chameleon_dictionary_reset();

                state-> resetCycle = DENSITY_DICTIONARY_PREFERRED_RESET_CYCLE - 1;
            }
#endif

            return DENSITY_KERNEL_ENCODE_STATE_INFO_NEW_BLOCK;
        default:
            break;
    }
    density_chameleon_encode_prepare_new_signature(out, state);

    return DENSITY_KERNEL_ENCODE_STATE_READY;
}

DENSITY_FORCE_INLINE DENSITY_KERNEL_ENCODE_STATE density_chameleon_encode_check_state(density_memory_location *restrict out, density_chameleon_encode_state *restrict state) {
    DENSITY_KERNEL_ENCODE_STATE returnState;

    switch (state->shift) {
        case density_bitsizeof(density_chameleon_signature):
            *(state->signature) = state->proximitySignature;
            if ((returnState = density_chameleon_encode_prepare_new_block(out, state)))
                return returnState;
            break;
        default:
            break;
    }

    return DENSITY_KERNEL_ENCODE_STATE_READY;
}

DENSITY_FORCE_INLINE void density_chameleon_encode_kernel(density_memory_location *restrict out, uint32_t *restrict hash, const uint32_t chunk, density_chameleon_encode_state *restrict state) {
    DENSITY_CHAMELEON_HASH_ALGORITHM(*hash, DENSITY_LITTLE_ENDIAN_32(chunk));
    density_chameleon_dictionary_entry *found = &state->dictionary.entries[*hash];

    if (chunk ^ found->as_uint32_t) {
        found->as_uint32_t = chunk;
        *(uint32_t *) (out->pointer) = chunk;
        out->pointer += sizeof(uint32_t);
    } else {
        density_chameleon_encode_write_to_signature(state);
        *(uint16_t *) (out->pointer) = DENSITY_LITTLE_ENDIAN_16(*hash);
        out->pointer += sizeof(uint16_t);
    }

    state->shift++;
}

DENSITY_FORCE_INLINE void density_chameleon_encode_process_chunk(uint64_t *chunk, density_memory_location *restrict in, density_memory_location *restrict out, uint32_t *restrict hash, density_chameleon_encode_state *restrict state) {
    *chunk = *(uint64_t *) (in->pointer);
#if __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
    density_chameleon_encode_kernel(out, hash, (uint32_t) (*chunk & 0xFFFFFFFF), state);
#endif
    density_chameleon_encode_kernel(out, hash, (uint32_t) (*chunk >> density_bitsizeof(uint32_t)), state);
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
    density_chameleon_encode_kernel(out, hash, (uint32_t)(*chunk & 0xFFFFFFFF), state);
#endif
    in->pointer += sizeof(uint64_t);
}

DENSITY_FORCE_INLINE void density_chameleon_encode_process_unit(uint64_t *chunk, density_memory_location *restrict in, density_memory_location *restrict out, uint32_t *restrict hash, density_chameleon_encode_state *restrict state) {
    density_chameleon_encode_process_chunk(chunk, in, out, hash, state);
    density_chameleon_encode_process_chunk(chunk, in, out, hash, state);
    density_chameleon_encode_process_chunk(chunk, in, out, hash, state);
    density_chameleon_encode_process_chunk(chunk, in, out, hash, state);
    density_chameleon_encode_process_chunk(chunk, in, out, hash, state);
    density_chameleon_encode_process_chunk(chunk, in, out, hash, state);
    density_chameleon_encode_process_chunk(chunk, in, out, hash, state);
    density_chameleon_encode_process_chunk(chunk, in, out, hash, state);
}

DENSITY_FORCE_INLINE DENSITY_KERNEL_ENCODE_STATE density_chameleon_encode_init(density_chameleon_encode_state *state) {
    state->signaturesCount = 0;
    state->efficiencyChecked = 0;
    density_chameleon_dictionary_reset(&state->dictionary);

#if DENSITY_ENABLE_PARALLELIZABLE_DECOMPRESSIBLE_OUTPUT == DENSITY_YES
    state->resetCycle = DENSITY_DICTIONARY_PREFERRED_RESET_CYCLE - 1;
#endif

    return exitProcess(state, DENSITY_CHAMELEON_ENCODE_PROCESS_PREPARE_NEW_BLOCK, DENSITY_KERNEL_ENCODE_STATE_READY);
}

#define DENSITY_CHAMELEON_ENCODE_CONTINUE
#define GENERIC_NAME(name) name ## continue
#include "kernel_chameleon_generic_encode.h"
#undef GENERIC_NAME
#undef DENSITY_CHAMELEON_ENCODE_CONTINUE

#define GENERIC_NAME(name) name ## finish
#include "kernel_chameleon_generic_encode.h"
#undef GENERIC_NAME