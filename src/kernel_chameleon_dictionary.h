/*
 * Centaurean libssc
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
 * 24/10/13 12:05
 */

#ifndef SSC_CHAMELEON_DICTIONARY_H
#define SSC_CHAMELEON_DICTIONARY_H

#include "globals.h"
#include "kernel_chameleon.h"

#include <string.h>

#pragma pack(push)
#pragma pack(4)
typedef struct {
    uint32_t layer_a;
    uint32_t layer_b;
} ssc_chameleon_dictionary_entry;

typedef struct {
    uint32_t next_chunk_prediction;
} ssc_chameleon_dictionary_prediction_entry;

typedef struct {
    ssc_chameleon_dictionary_entry entries[1 << SSC_CHAMELEON_HASH_BITS];
    ssc_chameleon_dictionary_prediction_entry prediction_entries[1 << SSC_CHAMELEON_HASH_BITS];
} ssc_chameleon_dictionary;
#pragma pack(pop)

void ssc_chameleon_dictionary_reset(ssc_chameleon_dictionary *);

#endif