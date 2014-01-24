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
 * 23/01/14 12:51
 */

#include "warper.h"

#define DENSITY_WARPER_MAIN_SWITCH      if (warper->buffer->available_bytes ^ warper->size) {\
                                            if (!warper->buffer->available_bytes)\
                                                density_warper_reset(warper);\
                                            else if (in->available_bytes < warper->buffer->available_bytes) {\
                                                density_warper_append_to_storage_buffer(warper, in);\
                                                return NULL;\
                                            } else {\
                                                density_warper_fill_storage_buffer(warper, in);\
                                                return warper->buffer;\
                                            }\
                                        }

#define DENSITY_WARPER_SECONDARY_SWITCH {\
                                            density_warper_append_to_storage_buffer(warper, in);\
                                            return NULL;\
                                        } else {\
                                            return in;\
                                        }


DENSITY_FORCE_INLINE density_warper_support_structure *density_warper_allocate(uint_fast32_t const size) {
    density_warper_support_structure *warper = (density_warper_support_structure *) malloc(sizeof(density_warper_support_structure));
    warper->buffer = (density_memory_location *) malloc(sizeof(density_memory_location));
    warper->buffer->pointer = (density_byte *) malloc(size * sizeof(density_byte));
    warper->buffer->available_bytes = size;
    warper->size = size;
    return warper;
}

DENSITY_FORCE_INLINE void density_warper_free(density_warper_support_structure *warper) {
    free(warper->buffer->pointer);
    free(warper->buffer);
    free(warper);
}

DENSITY_FORCE_INLINE void density_warper_reset(density_warper_support_structure *restrict warper) {
    warper->buffer->available_bytes = warper->size;
}

DENSITY_FORCE_INLINE void density_warper_append_to_storage_buffer(density_warper_support_structure *restrict warper, density_memory_location *restrict in) {
    memcpy(warper->buffer->pointer + (warper->size - warper->buffer->available_bytes), in->pointer, in->available_bytes);
    warper->buffer->available_bytes -= in->available_bytes;
    in->pointer += in->available_bytes;
    in->available_bytes = 0;
}

DENSITY_FORCE_INLINE void density_warper_fill_storage_buffer(density_warper_support_structure *restrict warper, density_memory_location *restrict in) {
    memcpy(warper->buffer->pointer + (warper->size - warper->buffer->available_bytes), in->pointer, warper->buffer->available_bytes);
    in->pointer += warper->buffer->available_bytes;
    in->available_bytes -= warper->buffer->available_bytes;
    warper->buffer->available_bytes = 0;
}

DENSITY_FORCE_INLINE density_memory_location *density_warper_fetch(density_warper_support_structure *restrict warper, density_memory_location *restrict in) {
    DENSITY_WARPER_MAIN_SWITCH
    if (in->available_bytes < warper->buffer->available_bytes)
    DENSITY_WARPER_SECONDARY_SWITCH
}

DENSITY_FORCE_INLINE density_memory_location *density_warper_fetch_using_limit(density_warper_support_structure *restrict warper, density_memory_location *restrict in, uint_fast64_t const limit) {
    DENSITY_WARPER_MAIN_SWITCH
    if (in->available_bytes == limit)
    DENSITY_WARPER_SECONDARY_SWITCH
}

DENSITY_FORCE_INLINE density_memory_location *density_warper_fetch_from_sub_span(density_warper_support_structure *restrict warper, density_memory_location *restrict in, const uint_fast32_t bytes) {
    uint_fast64_t remaining;
    if (warper->buffer->available_bytes ^ warper->size) {
        if (!warper->buffer->available_bytes)
            density_warper_reset(warper);
        else if (in->available_bytes < (remaining = warper->buffer->available_bytes - (warper->size - bytes))) {
            density_warper_append_to_storage_buffer(warper, in);
            return NULL;
        } else {
            memcpy(warper->buffer->pointer + (warper->size - warper->buffer->available_bytes), in->pointer, remaining);
            in->pointer += remaining;
            in->available_bytes -= remaining;
            warper->buffer->available_bytes = 0;
            return warper->buffer;
        }
    }
    remaining = warper->buffer->available_bytes - (warper->size - bytes);
    if (in->available_bytes < remaining) {
        density_warper_append_to_storage_buffer(warper, in);
        return NULL;
    } else {
        return in;
    }
}