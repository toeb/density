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
 * 23/01/14 12:51
 */

#include "kernel_encode_warp_pointer.h"
#include "kernel_chameleon_encode.h"

DENSITY_FORCE_INLINE density_memory_location *density_kernel_encode_warp_pointer_allocate_sub_buffer(const uint_fast32_t size) {
    density_memory_location* subBuffer = (density_memory_location *) malloc(sizeof(density_memory_location));
    subBuffer->pointer = (density_byte *) malloc(size * sizeof(density_byte));
    subBuffer->available_bytes = size;
    //reader->size = size;
    return subBuffer;
}

DENSITY_FORCE_INLINE void density_kernel_encode_warp_pointer_free_sub_buffer(density_memory_location *subBuffer) {
    free(subBuffer->pointer);
    free(subBuffer);
}

DENSITY_FORCE_INLINE density_memory_location *density_kernel_encode_warp_pointer_fetch(density_memory_location *subBuffer, density_memory_location *in, const uint_fast64_t limit, const uint_fast64_t resetSize) {
    if (subBuffer->available_bytes != resetSize) {
        if (!subBuffer->available_bytes)
            subBuffer->available_bytes = resetSize;
        else if (in->available_bytes < subBuffer->available_bytes) {
            memcpy(subBuffer + (resetSize - subBuffer->available_bytes), in->pointer, in->available_bytes);
            subBuffer->available_bytes -= in->available_bytes;
            in->pointer += in->available_bytes;
            in->available_bytes = 0;
            return NULL;
        } else {
            memcpy(subBuffer + (resetSize - subBuffer->available_bytes), in->pointer, subBuffer->available_bytes);
            subBuffer->available_bytes = 0;
            in->pointer += subBuffer->available_bytes;
            in->available_bytes -= subBuffer->available_bytes;
            return subBuffer;
        }
    }
    if (in->available_bytes == limit/*< subBuffer->size*/) {
        memcpy(subBuffer + (resetSize - subBuffer->available_bytes), in->pointer, in->available_bytes);
        subBuffer->available_bytes -= in->available_bytes;
        in->pointer += in->available_bytes;
        in->available_bytes = 0;
        return NULL;
    } else {
        return in;
    }
}