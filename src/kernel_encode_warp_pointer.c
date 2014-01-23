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

DENSITY_FORCE_INLINE density_kernel_encode_warp_pointer *density_kernel_encode_warp_pointer_allocate(uint_fast32_t size) {
    density_kernel_encode_warp_pointer *reader = (density_kernel_encode_warp_pointer *) malloc(sizeof(density_kernel_encode_warp_pointer));
    reader->buffer = (density_memory_location *) malloc(sizeof(density_memory_location));
    reader->buffer->pointer = (density_byte *) malloc(size * sizeof(density_byte));
    reader->buffer->available_bytes = size;
    reader->size = size;
    return reader;
}

DENSITY_FORCE_INLINE void density_kernel_encode_warp_pointer_free(density_kernel_encode_warp_pointer *reader) {
    free(reader->buffer->pointer);
    free(reader->buffer);
    free(reader);
}

DENSITY_FORCE_INLINE density_memory_location *density_kernel_encode_warp_pointer_fetch(density_kernel_encode_warp_pointer *encodeWarpPointer, density_memory_location *in, const uint_fast64_t limit) {
    if (!encodeWarpPointer->buffer->available_bytes)
        encodeWarpPointer->buffer->available_bytes = encodeWarpPointer->size;
    if (encodeWarpPointer->buffer->available_bytes < encodeWarpPointer->size) {
        if (in->available_bytes < encodeWarpPointer->buffer->available_bytes) {
            memcpy(encodeWarpPointer->buffer + (encodeWarpPointer->size - encodeWarpPointer->buffer->available_bytes), in->pointer, in->available_bytes);
            encodeWarpPointer->buffer->available_bytes -= in->available_bytes;
            in->pointer += in->available_bytes;
            in->available_bytes = 0;
            return NULL;
        } else {
            memcpy(encodeWarpPointer->buffer + (encodeWarpPointer->size - encodeWarpPointer->buffer->available_bytes), in->pointer, encodeWarpPointer->buffer->available_bytes);
            encodeWarpPointer->buffer->available_bytes = 0;
            in->pointer += encodeWarpPointer->buffer->available_bytes;
            in->available_bytes -= encodeWarpPointer->buffer->available_bytes;
            return encodeWarpPointer->buffer;
        }
    } else if (in->available_bytes == limit/*< warpPointer->size*/) {
        memcpy(encodeWarpPointer->buffer + (encodeWarpPointer->size - encodeWarpPointer->buffer->available_bytes), in->pointer, in->available_bytes);
        encodeWarpPointer->buffer->available_bytes -= in->available_bytes;
        in->pointer += in->available_bytes;
        in->available_bytes = 0;
        return NULL;
    } else {
        return in;
    }
}