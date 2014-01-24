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
 * 21/01/14 21:32
 */

#ifndef DENSITY_WARPER_H
#define DENSITY_WARPER_H

#include <string.h>
#include "density_api.h"
#include "globals.h"
#include "kernel_encode.h"

/*typedef enum {
    DENSITY_LOCATION_ORIGIN_UNAVAILABLE,
    DENSITY_LOCATION_ORIGIN_PROVIDED_BUFFER,
    DENSITY_LOCATION_ORIGIN_STORAGE_BUFFER,
} density_warper_memory_location_origin;*/

typedef struct {
    density_memory_location *buffer;
    uint_fast32_t size;
} density_warper_support_structure;

/*typedef struct {
    density_warper_memory_location_origin origin;
    density_memory_location* location;
} density_warper_memory_location;*/

density_warper_support_structure *density_warper_allocate(uint_fast32_t const);

void density_warper_free(density_warper_support_structure *);

density_memory_location *density_warper_fetch(density_warper_support_structure *, density_memory_location *);

density_memory_location *density_warper_fetch_using_limit(density_warper_support_structure *, density_memory_location *, uint_fast64_t const);

density_memory_location *density_warper_fetch_from_sub_span(density_warper_support_structure *, density_memory_location *, uint_fast32_t const);

#endif


