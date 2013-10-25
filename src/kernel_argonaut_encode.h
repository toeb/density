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

#ifndef SHARC_ARGONAUT_ENCODE_H
#define SHARC_ARGONAUT_ENCODE_H

#include "byte_buffer.h"
#include "block.h"
#include "kernel_encode.h"
#include "kernel_argonaut_dictionary.h"
#include "kernel_argonaut.h"
#include "main_encode.h"

#include <inttypes.h>
#include <math.h>
#include <stdint.h>

//#define SSC_HASH_ENCODE_MINIMUM_OUTPUT_LOOKAHEAD             (sizeof(ssc_hash_signature) + sizeof(uint32_t) * 8 * sizeof(ssc_hash_signature))

#define SSC_ARGONAUT_OUTPUT_UNIT_BIT_SIZE                         (sizeof(ssc_argonaut_output_unit) << 3)
//#define SSC_ARGONAUT_ENCODE_MINIMUM_OUTPUT_LOOKAHEAD_UNITS        8
//#define SSC_ARGONAUT_ENCODE_MINIMUM_OUTPUT_BYTES_LOOKAHEAD        (SSC_ARGONAUT_ENCODE_MINIMUM_OUTPUT_LOOKAHEAD_UNITS * SSC_ARGONAUT_OUTPUT_UNIT_BIT_SIZE)

#define SSC_ARGONAUT_ENCODE_PROCESS_RANKS
//#define SSC_ARGONAUT_ENCODE_PROCESS_LETTERS
//#define SSC_ARGONAUT_ENCODE_STATS

#define ssc_argonaut_contains_zero(search64) (((search64) - 0x0101010101010101llu) & ~(search64) & 0x8080808080808080llu)
#define ssc_argonaut_contains_value(search64, value8) (ssc_argonaut_contains_zero((search64) ^ (~0llu / 255 * (value8))))

typedef enum {
    //SSC_ARGONAUT_ENCODE_PROCESS_PREPARE_OUTPUT,
            SSC_ARGONAUT_ENCODE_PROCESS_CHECK_OUTPUT_MEMORY,
    //SSC_ARGONAUT_ENCODE_PROCESS_ALLOCATE_ANCHOR,
    //SSC_ARGONAUT_ENCODE_PROCESS_CHECK_AVAILABLE_MEMORY,
            SSC_ARGONAUT_ENCODE_PROCESS_GOTO_NEXT_WORD,
    SSC_ARGONAUT_ENCODE_PROCESS_WORD,
    SSC_ARGONAUT_ENCODE_PROCESS_FINISH
} SSC_ARGONAUT_ENCODE_PROCESS;

typedef enum {
    SSC_ARGONAUT_ENTITY_SEPARATOR = 0,
    SSC_ARGONAUT_ENTITY_RANKED_KEY = 1,
    SSC_ARGONAUT_ENTITY_WORD = 2,
    SSC_ARGONAUT_ENTITY_KEY = 3,
    SSC_ARGONAUT_ENTITY_COUNT
} SSC_ARGONAUT_ENTITY;

typedef struct {
    ssc_argonaut_huffman_code code[SSC_ARGONAUT_ENTITY_COUNT];
} ssc_argonaut_entity_code_lookup;

typedef uint_fast64_t ssc_argonaut_signature;
typedef uint_fast64_t ssc_argonaut_output_unit;

typedef struct {
    ssc_argonaut_huffman_code code [SSC_ARGONAUT_DICTIONARY_MAX_WORD_LETTERS];
} ssc_argonaut_word_length_code_lookup;

typedef struct {
    union {
        uint64_t as_uint64_t;
        //uint16_t as_uint16_t;
        uint8_t letters[SSC_ARGONAUT_DICTIONARY_MAX_WORD_LETTERS];
    };
    uint_fast8_t length; // todo
    //const ssc_argonaut_huffman_code* letterCode[SSC_ARGONAUT_DICTIONARY_MAX_WORD_LETTERS];
} ssc_argonaut_encode_word;

#pragma pack(push)
#pragma pack(4)
typedef struct {
    SSC_ARGONAUT_ENCODE_PROCESS process;

    //uint_fast64_t resetCycle;

    //uint_fast8_t efficiencyChecked;
    //ssc_argonaut_output_unit* output;
    //ssc_byte* anchor;
    uint_fast32_t shift;
    uint_fast16_t count;

    //uint_fast64_t bitCount;

    ssc_argonaut_encode_word word;

    //uint_fast32_t signatureShift;
    //ssc_argonaut_signature * signature;
    //uint_fast32_t signaturesCount;

    uint_fast64_t buffer;
    uint_fast8_t bufferBits;

    ssc_argonaut_dictionary dictionary;
} ssc_argonaut_encode_state;
#pragma pack(pop)

SSC_KERNEL_ENCODE_STATE ssc_argonaut_encode_init(void*);
SSC_KERNEL_ENCODE_STATE ssc_argonaut_encode_process(ssc_byte_buffer *, ssc_byte_buffer *, void *, const ssc_bool);
SSC_KERNEL_ENCODE_STATE ssc_argonaut_encode_finish(void*);

#endif