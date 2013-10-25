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
 * 25/10/13 23:05
 */

#ifndef SSC_ARGONAUT_DICTIONARY_H
#define SSC_ARGONAUT_DICTIONARY_H

#include "globals.h"
#include "kernel_argonaut.h"
#include "kernel_argonaut_le.data"

#include <string.h>

#define SSC_ARGONAUT_DICTIONARY_PRIMARY_RANKS                                             (256)
#define SSC_ARGONAUT_DICTIONARY_SECONDARY_RANKS                                           (256)
#define SSC_ARGONAUT_DICTIONARY_MAX_WORD_LETTERS                                          8
//#define SSC_ARGONAUT_DICTIONARY_TERTIARY_RANKS                                            (65536)

#pragma pack(push)
#pragma pack(4)
typedef struct ssc_argonaut_dictionary_primary_entry ssc_argonaut_dictionary_primary_entry;
struct ssc_argonaut_dictionary_primary_entry {
    uint_fast8_t letter;
    uint_fast32_t durability;
    uint_fast8_t ranking;
};

/*typedef struct ssc_argonaut_dictionary_tertiary_entry ssc_argonaut_dictionary_tertiary_entry;
struct ssc_argonaut_dictionary_tertiary_entry {
    uint_fast16_t diword;
    uint_fast32_t durability;
    uint_fast16_t ranking;
};*/

typedef struct {
    union {
        uint64_t as_uint64_t;
        //uint16_t as_uint16_t;
        uint8_t letters[SSC_ARGONAUT_DICTIONARY_MAX_WORD_LETTERS];
    };
    //uint_fast8_t length; // todo
    //const ssc_argonaut_huffman_code* letterCode[SSC_ARGONAUT_DICTIONARY_MAX_WORD_LETTERS];
} ssc_argonaut_dictionary_word;

typedef struct {
    ssc_argonaut_huffman_code code [SSC_ARGONAUT_DICTIONARY_PRIMARY_RANKS];
} ssc_argonaut_primary_code_lookup;

typedef struct {
    ssc_argonaut_huffman_code code [SSC_ARGONAUT_DICTIONARY_PRIMARY_RANKS * SSC_ARGONAUT_DICTIONARY_PRIMARY_RANKS];
} ssc_argonaut_secondary_code_lookup;

/*typedef struct {
    ssc_argonaut_huffman_code code [SSC_ARGONAUT_DICTIONARY_SECONDARY_RANKS];
} ssc_argonaut_secondary_code_lookup;*/

typedef struct {
    ssc_argonaut_dictionary_word word;
    uint_fast32_t durability;
    uint_fast8_t ranking;
    uint_fast8_t ranked;
} ssc_argonaut_dictionary_secondary_entry;

typedef struct {
    ssc_argonaut_dictionary_primary_entry *primary[SSC_ARGONAUT_DICTIONARY_PRIMARY_RANKS];
    ssc_argonaut_dictionary_secondary_entry *secondary[SSC_ARGONAUT_DICTIONARY_SECONDARY_RANKS];
    //ssc_argonaut_dictionary_tertiary_entry *tertiary[SSC_ARGONAUT_DICTIONARY_TERTIARY_RANKS];
} ssc_argonaut_dictionary_ranking;

typedef struct {
    ssc_argonaut_dictionary_ranking ranking;
    ssc_argonaut_dictionary_primary_entry primary_entry[1 << 8];
    ssc_argonaut_dictionary_secondary_entry secondary_entry[1 << 16];
    //ssc_argonaut_dictionary_tertiary_entry tertiary_entry[1 << 16];
} ssc_argonaut_dictionary;
#pragma pack(pop)

#endif