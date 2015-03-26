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
 * 18/10/13 00:03
 */

#include "block_encode.h"

DENSITY_REQUIRED_INLINE DENSITY_BLOCK_ENCODE_STATE exitProcess(density_block_encode_state *state, DENSITY_BLOCK_ENCODE_PROCESS process, DENSITY_BLOCK_ENCODE_STATE blockEncodeState) {
    state->process = process;
    return blockEncodeState;
}

DENSITY_FORCE_INLINE void density_block_encode_update_integrity_data(density_memory_teleport *restrict in, density_block_encode_state *restrict state) {
    state->integrityData.stagingAvailable = in->stagingMemoryLocation->memoryLocation->available_bytes;
    state->integrityData.stagingInputPointer = in->stagingMemoryLocation->memoryLocation->pointer;
    state->integrityData.directAvailable = in->directMemoryLocation->available_bytes;
    state->integrityData.directInputPointer = in->directMemoryLocation->pointer;

    state->integrityData.update = false;
}

DENSITY_FORCE_INLINE void density_block_encode_update_integrity_hash(density_memory_teleport *restrict in, density_block_encode_state *restrict state, bool pendingExit) {
    uint_fast64_t availableBefore = state->integrityData.stagingAvailable + state->integrityData.directAvailable;
    uint_fast64_t available = density_memory_teleport_available_bytes(in);
    uint_fast64_t used = availableBefore - available;

    if (used <= state->integrityData.stagingAvailable)
        spookyhash_update(state->integrityData.context, state->integrityData.stagingInputPointer, used);
    else {
        spookyhash_update(state->integrityData.context, state->integrityData.stagingInputPointer, state->integrityData.stagingAvailable);
        spookyhash_update(state->integrityData.context, state->integrityData.directInputPointer, used - state->integrityData.stagingAvailable);
    }

    if(pendingExit)
        state->integrityData.update = true;
    else
        density_block_encode_update_integrity_data(in, state);
}

DENSITY_FORCE_INLINE DENSITY_BLOCK_ENCODE_STATE density_block_encode_write_block_header(density_memory_teleport *restrict in, density_memory_location *restrict out, density_block_encode_state *restrict state) {
    if (sizeof(density_block_header) > out->available_bytes)
        return DENSITY_BLOCK_ENCODE_STATE_STALL_ON_OUTPUT;

    state->currentMode = state->targetMode;

    state->currentBlockData.inStart = state->totalRead;
    state->currentBlockData.outStart = state->totalWritten;

    state->totalWritten += density_block_header_write(out);

    if (state->blockType == DENSITY_BLOCK_TYPE_WITH_HASHSUM_INTEGRITY_CHECK) {
        spookyhash_context_init(state->integrityData.context, DENSITY_SPOOKYHASH_SEED_1, DENSITY_SPOOKYHASH_SEED_2);
        density_block_encode_update_integrity_data(in, state);
    }

    return DENSITY_BLOCK_ENCODE_STATE_READY;
}

DENSITY_FORCE_INLINE DENSITY_BLOCK_ENCODE_STATE density_block_encode_write_block_footer(density_memory_teleport *restrict in, density_memory_location *restrict out, density_block_encode_state *restrict state) {
    if (sizeof(density_block_footer) > out->available_bytes)
        return DENSITY_BLOCK_ENCODE_STATE_STALL_ON_OUTPUT;

    density_block_encode_update_integrity_hash(in, state, false);

    uint64_t hashsum1, hashsum2;
    spookyhash_final(state->integrityData.context, &hashsum1, &hashsum2);

    state->totalWritten += density_block_footer_write(out, hashsum1, hashsum2);

    return DENSITY_BLOCK_ENCODE_STATE_READY;
}

DENSITY_FORCE_INLINE DENSITY_BLOCK_ENCODE_STATE density_block_encode_write_mode_marker(density_memory_location *restrict out, density_block_encode_state *restrict state) {
    if (sizeof(density_mode_marker) > out->available_bytes)
        return DENSITY_BLOCK_ENCODE_STATE_STALL_ON_OUTPUT;

    switch (state->currentMode) {
        case DENSITY_COMPRESSION_MODE_COPY:
            break;

        default:
            if (state->totalWritten > state->totalRead)
                state->currentMode = DENSITY_COMPRESSION_MODE_COPY;
            break;
    }

    state->totalWritten += density_block_mode_marker_write(out, state->currentMode);

    return DENSITY_BLOCK_ENCODE_STATE_READY;
}

DENSITY_FORCE_INLINE void density_block_encode_update_totals(density_memory_teleport *restrict in, density_memory_location *restrict out, density_block_encode_state *restrict state, const uint_fast64_t availableInBefore, const uint_fast64_t availableOutBefore) {
    state->totalRead += availableInBefore - density_memory_teleport_available_bytes(in);
    state->totalWritten += availableOutBefore - out->available_bytes;
}

DENSITY_FORCE_INLINE DENSITY_BLOCK_ENCODE_STATE density_block_encode_init(density_block_encode_state *restrict state, const DENSITY_COMPRESSION_MODE mode, const DENSITY_BLOCK_TYPE blockType, void *kernelState, DENSITY_KERNEL_ENCODE_STATE (*kernelInit)(void *), DENSITY_KERNEL_ENCODE_STATE (*kernelProcess)(density_memory_teleport *, density_memory_location *, void *), DENSITY_KERNEL_ENCODE_STATE (*kernelFinish)(density_memory_teleport *, density_memory_location *, void *), void *(*mem_alloc)(size_t)) {
    state->blockType = blockType;
    state->targetMode = mode;
    state->currentMode = mode;

    state->totalRead = 0;
    state->totalWritten = 0;

    if (state->blockType == DENSITY_BLOCK_TYPE_WITH_HASHSUM_INTEGRITY_CHECK) {
        state->integrityData.context = spookyhash_context_allocate(mem_alloc);
        state->integrityData.update = true;
    }

    switch (state->currentMode) {
        case DENSITY_COMPRESSION_MODE_COPY:
            break;
        default:
            state->kernelEncodeState = kernelState;
            state->kernelEncodeInit = kernelInit;
            state->kernelEncodeProcess = kernelProcess;
            state->kernelEncodeFinish = kernelFinish;

            state->kernelEncodeInit(state->kernelEncodeState);
            break;
    }

    return exitProcess(state, DENSITY_BLOCK_ENCODE_PROCESS_WRITE_BLOCK_HEADER, DENSITY_BLOCK_ENCODE_STATE_READY);
}

DENSITY_FORCE_INLINE DENSITY_BLOCK_ENCODE_STATE density_block_encode_continue(density_memory_teleport *restrict in, density_memory_location *restrict out, density_block_encode_state *restrict state) {
    DENSITY_BLOCK_ENCODE_STATE blockEncodeState;
    DENSITY_KERNEL_ENCODE_STATE kernelEncodeState;
    uint_fast64_t availableInBefore;
    uint_fast64_t availableOutBefore;
    uint_fast64_t blockRemaining;
    uint_fast64_t inRemaining;
    uint_fast64_t outRemaining;

    // Add to the integrity check hashsum
    if (state->blockType == DENSITY_BLOCK_TYPE_WITH_HASHSUM_INTEGRITY_CHECK && state->integrityData.update)
        density_block_encode_update_integrity_data(in, state);

    // Dispatch
    switch (state->process) {
        case DENSITY_BLOCK_ENCODE_PROCESS_WRITE_BLOCK_HEADER:
            goto write_block_header;
        case DENSITY_BLOCK_ENCODE_PROCESS_WRITE_BLOCK_MODE_MARKER:
            goto write_mode_marker;
        case DENSITY_BLOCK_ENCODE_PROCESS_WRITE_DATA:
            goto write_data;
        case DENSITY_BLOCK_ENCODE_PROCESS_WRITE_BLOCK_FOOTER:
            goto write_block_footer;
        default:
            return DENSITY_BLOCK_ENCODE_STATE_ERROR;
    }

    write_mode_marker:
    if ((blockEncodeState = density_block_encode_write_mode_marker(out, state)))
        return exitProcess(state, DENSITY_BLOCK_ENCODE_PROCESS_WRITE_BLOCK_MODE_MARKER, blockEncodeState);
    goto write_data;

    write_block_header:
    if ((blockEncodeState = density_block_encode_write_block_header(in, out, state)))
        return exitProcess(state, DENSITY_BLOCK_ENCODE_PROCESS_WRITE_BLOCK_HEADER, blockEncodeState);

    write_data:
    availableInBefore = density_memory_teleport_available_bytes(in);
    availableOutBefore = out->available_bytes;

    switch (state->currentMode) {
        case DENSITY_COMPRESSION_MODE_COPY:
            blockRemaining = (uint_fast64_t) DENSITY_PREFERRED_COPY_BLOCK_SIZE - (state->totalRead - state->currentBlockData.inStart);
            inRemaining = density_memory_teleport_available_bytes(in);
            outRemaining = out->available_bytes;

            if (inRemaining <= outRemaining) {
                if (blockRemaining <= inRemaining)
                    goto copy_until_end_of_block;
                else {
                    density_memory_teleport_copy(in, out, inRemaining);
                    density_block_encode_update_totals(in, out, state, availableInBefore, availableOutBefore);
                    if (state->blockType == DENSITY_BLOCK_TYPE_WITH_HASHSUM_INTEGRITY_CHECK)
                        density_block_encode_update_integrity_hash(in, state, true);
                    return exitProcess(state, DENSITY_BLOCK_ENCODE_PROCESS_WRITE_DATA, DENSITY_BLOCK_ENCODE_STATE_STALL_ON_INPUT);
                }
            } else {
                if (blockRemaining <= outRemaining)
                    goto copy_until_end_of_block;
                else {
                    density_memory_teleport_copy(in, out, outRemaining);
                    density_block_encode_update_totals(in, out, state, availableInBefore, availableOutBefore);
                    return exitProcess(state, DENSITY_BLOCK_ENCODE_PROCESS_WRITE_DATA, DENSITY_BLOCK_ENCODE_STATE_STALL_ON_OUTPUT);
                }
            }

        copy_until_end_of_block:
            density_memory_teleport_copy(in, out, blockRemaining);
            density_block_encode_update_totals(in, out, state, availableInBefore, availableOutBefore);
            goto write_block_footer;

        default:
            kernelEncodeState = state->kernelEncodeProcess(in, out, state->kernelEncodeState);
            density_block_encode_update_totals(in, out, state, availableInBefore, availableOutBefore);

            switch (kernelEncodeState) {
                case DENSITY_KERNEL_ENCODE_STATE_STALL_ON_INPUT:
                    if (state->blockType == DENSITY_BLOCK_TYPE_WITH_HASHSUM_INTEGRITY_CHECK)
                        density_block_encode_update_integrity_hash(in, state, true);
                    return exitProcess(state, DENSITY_BLOCK_ENCODE_PROCESS_WRITE_DATA, DENSITY_BLOCK_ENCODE_STATE_STALL_ON_INPUT);
                case DENSITY_KERNEL_ENCODE_STATE_STALL_ON_OUTPUT:
                    return exitProcess(state, DENSITY_BLOCK_ENCODE_PROCESS_WRITE_DATA, DENSITY_BLOCK_ENCODE_STATE_STALL_ON_OUTPUT);
                case DENSITY_KERNEL_ENCODE_STATE_INFO_NEW_BLOCK:
                    goto write_block_footer;
                case DENSITY_KERNEL_ENCODE_STATE_INFO_EFFICIENCY_CHECK:
                    goto write_mode_marker;
                default:
                    return DENSITY_BLOCK_ENCODE_STATE_ERROR;
            }
    }

    write_block_footer:
    if (state->blockType == DENSITY_BLOCK_TYPE_WITH_HASHSUM_INTEGRITY_CHECK) if ((blockEncodeState = density_block_encode_write_block_footer(in, out, state)))
        return exitProcess(state, DENSITY_BLOCK_ENCODE_PROCESS_WRITE_BLOCK_FOOTER, blockEncodeState);
    goto write_block_header;
}

DENSITY_FORCE_INLINE DENSITY_BLOCK_ENCODE_STATE density_block_encode_finish(density_memory_teleport *restrict in, density_memory_location *restrict out, density_block_encode_state *restrict state, void (*mem_free)(void *)) {
    DENSITY_BLOCK_ENCODE_STATE blockEncodeState;
    DENSITY_KERNEL_ENCODE_STATE kernelEncodeState;
    uint_fast64_t availableInBefore;
    uint_fast64_t availableOutBefore;
    uint_fast64_t blockRemaining;
    uint_fast64_t inRemaining;
    uint_fast64_t outRemaining;

    // Add to the integrity check hashsum
    if (state->blockType == DENSITY_BLOCK_TYPE_WITH_HASHSUM_INTEGRITY_CHECK && state->integrityData.update)
        density_block_encode_update_integrity_data(in, state);

    // Dispatch
    switch (state->process) {
        case DENSITY_BLOCK_ENCODE_PROCESS_WRITE_BLOCK_HEADER:
            goto write_block_header;
        case DENSITY_BLOCK_ENCODE_PROCESS_WRITE_BLOCK_MODE_MARKER:
            goto write_mode_marker;
        case DENSITY_BLOCK_ENCODE_PROCESS_WRITE_DATA:
            goto write_data;
        case DENSITY_BLOCK_ENCODE_PROCESS_WRITE_BLOCK_FOOTER:
            goto write_block_footer;
        default:
            return DENSITY_BLOCK_ENCODE_STATE_ERROR;
    }

    write_mode_marker:
    if ((blockEncodeState = density_block_encode_write_mode_marker(out, state)))
        return exitProcess(state, DENSITY_BLOCK_ENCODE_PROCESS_WRITE_BLOCK_MODE_MARKER, blockEncodeState);
    goto write_data;

    write_block_header:
    if ((blockEncodeState = density_block_encode_write_block_header(in, out, state)))
        return exitProcess(state, DENSITY_BLOCK_ENCODE_PROCESS_WRITE_BLOCK_HEADER, blockEncodeState);

    write_data:
    availableInBefore = density_memory_teleport_available_bytes(in);
    availableOutBefore = out->available_bytes;

    switch (state->currentMode) {
        case DENSITY_COMPRESSION_MODE_COPY:
            blockRemaining = (uint_fast64_t) DENSITY_PREFERRED_COPY_BLOCK_SIZE - (state->totalRead - state->currentBlockData.inStart);
            inRemaining = density_memory_teleport_available_bytes(in);
            outRemaining = out->available_bytes;

            if (inRemaining <= outRemaining) {
                if (blockRemaining <= inRemaining)
                    goto copy_until_end_of_block;
                else {
                    density_memory_teleport_copy(in, out, inRemaining);
                    density_block_encode_update_totals(in, out, state, availableInBefore, availableOutBefore);
                    goto write_block_footer;
                }
            } else {
                if (blockRemaining <= outRemaining)
                    goto copy_until_end_of_block;
                else {
                    density_memory_teleport_copy(in, out, outRemaining);
                    density_block_encode_update_totals(in, out, state, availableInBefore, availableOutBefore);
                    return exitProcess(state, DENSITY_BLOCK_ENCODE_PROCESS_WRITE_DATA, DENSITY_BLOCK_ENCODE_STATE_STALL_ON_OUTPUT);
                }
            }

        copy_until_end_of_block:
            density_memory_teleport_copy(in, out, blockRemaining);
            density_block_encode_update_totals(in, out, state, availableInBefore, availableOutBefore);
            goto write_block_footer;

        default:
            kernelEncodeState = state->kernelEncodeFinish(in, out, state->kernelEncodeState);
            density_block_encode_update_totals(in, out, state, availableInBefore, availableOutBefore);

            switch (kernelEncodeState) {
                case DENSITY_KERNEL_ENCODE_STATE_STALL_ON_INPUT:
                    return DENSITY_BLOCK_ENCODE_STATE_ERROR;
                case DENSITY_KERNEL_ENCODE_STATE_STALL_ON_OUTPUT:
                    return exitProcess(state, DENSITY_BLOCK_ENCODE_PROCESS_WRITE_DATA, DENSITY_BLOCK_ENCODE_STATE_STALL_ON_OUTPUT);
                case DENSITY_KERNEL_ENCODE_STATE_READY:
                case DENSITY_KERNEL_ENCODE_STATE_INFO_NEW_BLOCK:
                    goto write_block_footer;
                case DENSITY_KERNEL_ENCODE_STATE_INFO_EFFICIENCY_CHECK:
                    goto write_mode_marker;
                default:
                    return DENSITY_BLOCK_ENCODE_STATE_ERROR;
            }
    }

    write_block_footer:
    if (state->blockType == DENSITY_BLOCK_TYPE_WITH_HASHSUM_INTEGRITY_CHECK) if ((blockEncodeState = density_block_encode_write_block_footer(in, out, state)))
        return exitProcess(state, DENSITY_BLOCK_ENCODE_PROCESS_WRITE_BLOCK_FOOTER, blockEncodeState);
    if (density_memory_teleport_available_bytes(in))
        goto write_block_header;

    if (state->blockType == DENSITY_BLOCK_TYPE_WITH_HASHSUM_INTEGRITY_CHECK)
        spookyhash_context_free(state->integrityData.context, mem_free);

    return DENSITY_BLOCK_ENCODE_STATE_READY;
}