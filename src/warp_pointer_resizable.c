/*
 * Centaurean Density
 * http://www.libssc.net
 *
 * Copyright (c) 2014, Guillaume Voirin
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
 * 23/01/14 17:17
 */

#include "warp_pointer_resizable.h"

DENSITY_FORCE_INLINE density_warp_pointer_resizable *density_kernel_pointer_resizable_allocate(const uint_fast32_t maxSize) {
    density_warp_pointer_resizable *warpPointer = (density_warp_pointer_resizable *) malloc(sizeof(density_warp_pointer_resizable));
    warpPointer->buffer = (density_memory_location *) malloc(sizeof(density_memory_location));
    warpPointer->buffer->pointer = (density_byte *) malloc(maxSize * sizeof(density_byte));
    warpPointer->buffer->available_bytes = maxSize;
    warpPointer->realSize = maxSize;
    warpPointer->currentSize = maxSize;
    return warpPointer;
}

DENSITY_FORCE_INLINE void density_warp_pointer_resizable_free(density_warp_pointer_resizable *warpPointer) {
    free(warpPointer->buffer->pointer);
    free(warpPointer->buffer);
    free(warpPointer);
}

DENSITY_FORCE_INLINE void density_warp_pointer_resizable_reset(density_warp_pointer_resizable *warpPointer, const uint_fast32_t size) {
    warpPointer->buffer->available_bytes = size;
    warpPointer->currentSize = size;
}

DENSITY_FORCE_INLINE density_memory_location *density_warp_pointer_resizable_fetch(density_warp_pointer_resizable *restrict warpPointer, density_memory_location *restrict in, const uint_fast64_t limit) {
    if (warpPointer->buffer->available_bytes ^ warpPointer->currentSize) {
        if (!warpPointer->buffer->available_bytes)
            density_warp_pointer_resizable_reset(warpPointer, warpPointer->currentSize);
        else if (in->available_bytes < warpPointer->buffer->available_bytes) {
            memcpy(warpPointer->buffer + (warpPointer->currentSize - warpPointer->buffer->available_bytes), in->pointer, in->available_bytes);
            warpPointer->buffer->available_bytes -= in->available_bytes;
            in->pointer += in->available_bytes;
            in->available_bytes = 0;
            return NULL;
        } else {
            memcpy(warpPointer->buffer + (warpPointer->currentSize - warpPointer->buffer->available_bytes), in->pointer, warpPointer->buffer->available_bytes);
            in->pointer += warpPointer->buffer->available_bytes;
            in->available_bytes -= warpPointer->buffer->available_bytes;
            warpPointer->buffer->available_bytes = 0;
            return warpPointer->buffer;
        }
    }
    if (in->available_bytes == limit) {
        memcpy(warpPointer->buffer + (warpPointer->currentSize - warpPointer->buffer->available_bytes), in->pointer, in->available_bytes);
        warpPointer->buffer->available_bytes -= in->available_bytes;
        in->pointer += in->available_bytes;
        in->available_bytes = 0;
        return NULL;
    } else {
        return in;
    }
}