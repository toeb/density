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
 * 25/10/13 23:06
 */

#include "kernel_argonaut_encode.h"

#define BLOCK   512

#ifdef SSC_ARGONAUT_ENCODE_PROCESS_LETTERS
const ssc_argonaut_primary_code_lookup hl = {.code = SSC_ARGONAUT_PRIMARY_HUFFMAN_CODES};
//const ssc_argonaut_secondary_code_lookup ARGONAUT_NAME(h2l) = {.code = SSC_ARGONAUT_PRIMARY_HUFFMAN_CODES_2};
#endif
//const ssc_argonaut_secondary_code_lookup ARGONAUT_NAME(shl) = {.code = SSC_ARGONAUT_SECONDARY_HUFFMAN_CODES};
//const ssc_argonaut_word_length_code_lookup ARGONAUT_NAME(wlhl) = {.code = SSC_ARGONAUT_WORD_LENGTH_HUFFMAN_CODES};
//const ssc_argonaut_entity_code_lookup ARGONAUT_NAME(ehl) = {.code = SSC_ARGONAUT_ENTITY_HUFFMAN_CODES};

/*SSC_FORCE_INLINE void ssc_argonaut_encode_write_to_signature(ssc_argonaut_encode_state *state, uint_fast8_t value) {
#if __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
    *(state->signature) |= ((uint64_t) value) << state->shift;
#elif __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
    *(state->signature) |= ((uint64_t) value) << ((56 - (state->shift & ~0x7)) + (state->shift & 0x7));
#endif
}*/

SSC_FORCE_INLINE SSC_KERNEL_ENCODE_STATE ssc_argonaut_encode_prepare_new_block(ssc_byte_buffer *restrict out, ssc_argonaut_encode_state *restrict state, const uint_fast32_t minimumLookahead) {
    out->position += (state->shift >> 3);
    state->shift &= 0x7llu;
    if (out->position + minimumLookahead > out->size)
        return SSC_KERNEL_ENCODE_STATE_STALL_ON_OUTPUT_BUFFER;
    state->count = BLOCK;

/*switch (state->signaturesCount) {
    case SSC_PREFERRED_EFFICIENCY_CHECK_SIGNATURES:
        if (state->efficiencyChecked ^ 0x1) {
            state->efficiencyChecked = 1;
            return SSC_KERNEL_ENCODE_STATE_INFO_EFFICIENCY_CHECK;
        }
        break;
    case SSC_PREFERRED_BLOCK_SIGNATURES:
        state->signaturesCount = 0;
        state->efficiencyChecked = 0;
        
        if (state->resetCycle)
            state->resetCycle--;
        else {
            // todo ?
            state->resetCycle = SSC_DICTIONARY_PREFERRED_RESET_CYCLE - 1;
        }
        
        return SSC_KERNEL_ENCODE_STATE_INFO_NEW_BLOCK;
    default:
        break;
}
state->signaturesCount++;

state->signatureShift = 0;
state->signature = (ssc_argonaut_signature *) (out->pointer + out->position);
*state->signature = 0;
out->position += sizeof(ssc_argonaut_signature);*/

//tate->output = (ssc_argonaut_signature *) (out->pointer + out->position);
//state->anchor = out->pointer + out->position;

    return SSC_KERNEL_ENCODE_STATE_READY;
}

/*SSC_FORCE_INLINE SSC_KERNEL_ENCODE_STATE ssc_argonaut_encode_check_state(ssc_byte_buffer *restrict out, ssc_argonaut_encode_state *restrict state) {
    SSC_KERNEL_ENCODE_STATE returnState;
    
    switch (state->signatureShift) {
        case 64:
            if ((returnState = ssc_argonaut_encode_prepare_new_block(out, state, SSC_HASH_ENCODE_MINIMUM_OUTPUT_LOOKAHEAD))) {
                state->process = SSC_ARGONAUT_ENCODE_PROCESS_PREPARE_NEW_BLOCK;
                return returnState;
            }
            break;
        default:
            break;
    }
    
    return SSC_KERNEL_ENCODE_STATE_READY;
}*/

/*SSC_FORCE_INLINE SSC_KERNEL_ENCODE_STATE ssc_argonaut_encode_check_next_output_block_memory_available(ssc_byte_buffer *restrict out, ssc_argonaut_encode_state *restrict state) {
    if (out->position + 24 > out->size)
        return SSC_KERNEL_ENCODE_STATE_STALL_ON_OUTPUT_BUFFER;

    //state->blockShift = 0;

    return SSC_KERNEL_ENCODE_STATE_READY;
}*/

/*SSC_FORCE_INLINE void ssc_argonaut_encode_prepare_next_output_unit_even(ssc_byte_buffer *restrict out, ssc_argonaut_encode_state *restrict state) {
    state->shift = 0;

    state->output = (ssc_argonaut_output_unit *) (out->pointer + out->position);
    *(state->output) = 0;
    out->position += sizeof(ssc_argonaut_output_unit);
}

SSC_FORCE_INLINE void ssc_argonaut_encode_prepare_next_output_unit(ssc_byte_buffer *restrict out, ssc_argonaut_encode_state *restrict state, const uint_fast64_t data, const uint_fast8_t bitSize) {
    state->shift = (uint8_t) (state->shift - SSC_ARGONAUT_OUTPUT_UNIT_BIT_SIZE);

    state->output = (ssc_argonaut_output_unit *) (out->pointer + out->position);
    *(state->output) = (ssc_argonaut_output_unit) (data >> (bitSize - state->shift));
    out->position += sizeof(ssc_argonaut_output_unit);
}*/

SSC_FORCE_INLINE void ssc_argonaut_encode_write_to_output(ssc_byte_buffer *restrict out, ssc_argonaut_encode_state *state, const uint_fast32_t value, const uint_fast8_t bitSize) {
#if __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
    *(uint_fast32_t *) (out->pointer + out->position + (state->shift >> 3)) += ((/*(uint_fast64_t)*/ value) << (state->shift & 0x7)); // 18 bits max << 8 = 26
    //*(state->output) |= value << state->shift;
#elif __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
    *(state->output) |= value << ((56 - (state->shift & ~0x7)) + (state->shift & 0x7));
#endif
    state->shift += bitSize;
}

/*SSC_FORCE_INLINE void ssc_argonaut_encode_write_coded_separator(ssc_byte_buffer *restrict out, ssc_argonaut_encode_state *restrict state) {
    ssc_argonaut_encode_write_to_output(state, ARGONAUT_NAME(ehl).code[SSC_ARGONAUT_ENTITY_SEPARATOR].code);

    state->shift++;
    if (state->shift == SSC_ARGONAUT_OUTPUT_UNIT_BIT_SIZE)
        ssc_argonaut_encode_prepare_next_output_unit_even(out, state);
}*/

/*SSC_FORCE_INLINE void ssc_argonaut_encode_write(ssc_byte_buffer *restrict out, ssc_argonaut_encode_state *restrict state, const uint_fast64_t data, const uint_fast8_t bitSize) {
    ssc_argonaut_encode_write_to_output(state, data);

    state->shift += bitSize;
    //if (state->shift & ~(SSC_ARGONAUT_OUTPUT_UNIT_BIT_SIZE - 1))
    //    ssc_argonaut_encode_prepare_next_output_unit(out, state, data, bitSize);
}

SSC_FORCE_INLINE void ssc_argonaut_encode_write_coded(ssc_byte_buffer *restrict out, ssc_argonaut_encode_state *restrict state, const ssc_argonaut_huffman_code *restrict code) {
    ssc_argonaut_encode_write(out, state, code->code, code->bitSize);
}*/

SSC_FORCE_INLINE void ssc_argonaut_encode_process_letter(ssc_byte_buffer *restrict out, ssc_argonaut_encode_state *restrict state, ssc_argonaut_dictionary_word *restrict word, const uint8_t *restrict letter, const uint8_t index, uint_fast32_t *restrict hash, uint8_t *restrict separator) {
    //*hash = *hash ^ *letter;
    //*hash = *hash * SSC_ARGONAUT_HASH_PRIME;

#ifdef SSC_ARGONAUT_ENCODE_PROCESS_LETTERS
    /*ssc_argonaut_dictionary_primary_entry *match = &state->dictionary.primary_entry[*letter];

    const uint8_t rank = match->ranking;
    const uint8_t precedingRank = match->ranking - 1;

    const ssc_argonaut_huffman_code *huffmanCode = &ARGONAUT_NAME(hl).code[rank];
    word->letterCode[index] = huffmanCode;

    match->durability++;
    ssc_argonaut_dictionary_primary_entry *preceding_match = state->dictionary.ranking.primary[precedingRank];
    if (preceding_match->durability < match->durability) {
        state->dictionary.ranking.primary[precedingRank] = match;
        state->dictionary.ranking.primary[rank] = preceding_match;
        match->ranking -= 1;
        if (!match->ranking)
            *separator = *letter;
        preceding_match->ranking += 1;
    }*/
#endif
}

/*SSC_FORCE_INLINE uint8_t ssc_argonaut_encode_advance_to_separator(ssc_byte_buffer *restrict out, ssc_argonaut_encode_state *restrict state, uint_fast8_t *restrict letter, uint_fast32_t *restrict hash, ssc_argonaut_dictionary_word *restrict word, uint8_t *separator) {
    *hash = SSC_ARGONAUT_HASH_OFFSET_BASIS;
    if ((*letter = word->letters[0]) ^ *separator) {
        ssc_argonaut_encode_process_letter(out, state, word, letter, 0, hash, separator);
        if ((*letter = word->letters[1]) ^ *separator) {
            ssc_argonaut_encode_process_letter(out, state, word, letter, 1, hash, separator);
            if ((*letter = word->letters[2]) ^ *separator) {
                ssc_argonaut_encode_process_letter(out, state, word, letter, 2, hash, separator);
                if ((*letter = word->letters[3]) ^ *separator) {
                    ssc_argonaut_encode_process_letter(out, state, word, letter, 3, hash, separator);
                    if ((*letter = word->letters[4]) ^ *separator) {
                        ssc_argonaut_encode_process_letter(out, state, word, letter, 4, hash, separator);
                        if ((*letter = word->letters[5]) ^ *separator) {
                            ssc_argonaut_encode_process_letter(out, state, word, letter, 5, hash, separator);
                            if ((*letter = word->letters[6]) ^ *separator) {
                                ssc_argonaut_encode_process_letter(out, state, word, letter, 6, hash, separator);
                                if ((*letter = word->letters[7]) ^ *separator) {
                                    ssc_argonaut_encode_process_letter(out, state, word, letter, 7, hash, separator);
                                    return 8;
                                } else
                                    return 7;
                            } else
                                return 6;
                        } else
                            return 5;
                    } else
                        return 4;
                } else
                    return 3;
            } else
                return 2;
        } else
            return 1;
    } else
        return 0;
}

SSC_FORCE_INLINE uint8_t ssc_argonaut_encode_find_first_separator_position_limited(ssc_byte_buffer *restrict out, ssc_argonaut_encode_state *restrict state, uint_fast8_t start, uint_fast8_t stop, uint_fast8_t *restrict letter, uint_fast32_t *restrict hash, ssc_argonaut_dictionary_word *restrict word, uint8_t *separator) {
    if (!start)
        *hash = SSC_ARGONAUT_HASH_OFFSET_BASIS;
    if ((start != stop) && (*letter = word->letters[start]) ^ *separator) {
        start++;
        ssc_argonaut_encode_process_letter(out, state, word, letter, 0, hash, separator);
        if ((start != stop) && (*letter = word->letters[start]) ^ *separator) {
            start++;
            ssc_argonaut_encode_process_letter(out, state, word, letter, 1, hash, separator);
            if ((start != stop) && (*letter = word->letters[start]) ^ *separator) {
                start++;
                ssc_argonaut_encode_process_letter(out, state, word, letter, 2, hash, separator);
                if ((start != stop) && (*letter = word->letters[start]) ^ *separator) {
                    start++;
                    ssc_argonaut_encode_process_letter(out, state, word, letter, 3, hash, separator);
                    if ((start != stop) && (*letter = word->letters[start]) ^ *separator) {
                        start++;
                        ssc_argonaut_encode_process_letter(out, state, word, letter, 4, hash, separator);
                        if ((start != stop) && (*letter = word->letters[start]) ^ *separator) {
                            start++;
                            ssc_argonaut_encode_process_letter(out, state, word, letter, 5, hash, separator);
                            if ((start != stop) && (*letter = word->letters[start]) ^ *separator) {
                                start++;
                                ssc_argonaut_encode_process_letter(out, state, word, letter, 6, hash, separator);
                                if ((start != stop) && (*letter = word->letters[start]) ^ *separator) {
                                    ssc_argonaut_encode_process_letter(out, state, word, letter, 7, hash, separator);
                                    return 8;
                                } else
                                    return 7;
                            } else
                                return 6;
                        } else
                            return 5;
                    } else
                        return 4;
                } else
                    return 3;
            } else
                return 2;
        } else
            return 1;
    } else
        return 0;
}*/

SSC_FORCE_INLINE uint_fast8_t ssc_argonaut_encode_find_position(uint64_t chain) {
    if (chain) {
        uint_fast32_t word_beginning = (uint_fast32_t) (chain & 0xFFFFFFFF);
        if (word_beginning)
            return __builtin_ctz(word_beginning) >> 3;
        else {
            uint_fast32_t word_end = (uint_fast32_t) (chain >> 32);
            return 4 + (__builtin_ctz(word_end) >> 3);
        }
    } else
        return (uint_fast8_t) sizeof(uint64_t);
}

SSC_FORCE_INLINE uint_fast8_t ssc_argonaut_encode_find_first_separator_position(uint64_t *restrict chain, uint8_t *restrict separator) {
    return ssc_argonaut_encode_find_position(ssc_argonaut_contains_value(*chain, *separator));
}

/*SSC_FORCE_INLINE uint_fast8_t ssc_argonaut_find_first_non_separator_position(uint64_t *restrict chain, uint8_t *restrict separator) {
    return ssc_argonaut_encode_find_position(ssc_argonaut_contains_value(*chain, *separator) ^ 0x8080808080808080llu);
}*/

SSC_FORCE_INLINE uint_fast8_t ssc_argonaut_encode_add_letters_until_separator_limited(ssc_byte_buffer *restrict in, uint8_t *restrict separator, uint_fast64_t limit) {
    uint_fast64_t start = in->position;
    while (limit--) {
        if (*(in->pointer + in->position) == *separator)
            return (uint_fast8_t) (in->position - start);
        in->position++;
    }
    return (uint_fast8_t) (in->position - start);
}

SSC_FORCE_INLINE SSC_KERNEL_ENCODE_STATE ssc_argonaut_encode_find_next_word(ssc_byte_buffer *restrict in, ssc_byte_buffer *restrict out, ssc_argonaut_encode_state *restrict state, uint8_t *separator) {
    while (*(in->pointer + in->position) == *separator) {
/*if (unlikely(out->position + (state->shift >> 3) == out->size - 1))
    return SSC_KERNEL_ENCODE_STATE_STALL_ON_OUTPUT_BUFFER;*/
        state->shift += 2;
        state->dictionary.ranking.primary[0]->durability++;
        in->position++;
        if (ssc_unlikely(in->position == in->size))
            return SSC_KERNEL_ENCODE_STATE_STALL_ON_INPUT_BUFFER;
/*if(unlikely(1 == state->count --))
    return SSC_KERNEL_ENCODE_STATE_READY;*/
    }
//if (unlikely(out->size - out->position < 24))
//    return SSC_KERNEL_ENCODE_STATE_STALL_ON_OUTPUT_BUFFER;

    return SSC_KERNEL_ENCODE_STATE_READY;
}

SSC_FORCE_INLINE SSC_KERNEL_ENCODE_STATE ssc_argonaut_encode_process_word(ssc_byte_buffer *restrict in, ssc_byte_buffer *restrict out, uint_fast8_t *letter, uint_fast32_t *restrict hash, ssc_argonaut_encode_state *restrict state, uint8_t *separator) {
/*if (unlikely(out->position + (state->shift >> 3) > out->size - 24))
    return SSC_KERNEL_ENCODE_STATE_STALL_ON_OUTPUT_BUFFER;*/
    if (ssc_unlikely(state->word.length)) {
        state->word.as_uint64_t |= ((*(uint64_t *) (in->pointer + in->position)) << state->word.length);
        const uint8_t addedLength = ssc_argonaut_encode_add_letters_until_separator_limited(in, separator, (uint_fast64_t) (SSC_ARGONAUT_DICTIONARY_MAX_WORD_LETTERS - state->word.length));
        state->word.length += addedLength;
    } else {
        state->word.as_uint64_t = *(uint64_t *) (in->pointer + in->position);
        if (ssc_likely(in->size - in->position > SSC_ARGONAUT_DICTIONARY_MAX_WORD_LETTERS)) {
            state->word.length = ssc_argonaut_encode_find_first_separator_position(&state->word.as_uint64_t, separator);
            in->position += state->word.length;
        } else {
            const uint8_t remaining = (uint8_t) (in->size - in->position);
            state->word.length = ssc_argonaut_encode_add_letters_until_separator_limited(in, separator, remaining/*in->size*/);
            if (state->word.length == remaining) {
                state->word.as_uint64_t &= ((((uint64_t) 1) << (state->word.length << 3)) - 1);
                return SSC_KERNEL_ENCODE_STATE_STALL_ON_INPUT_BUFFER;
            }
        }
    }

    const uint_fast8_t wordLength = state->word.length;
    if (wordLength ^ SSC_ARGONAUT_DICTIONARY_MAX_WORD_LETTERS)
        state->word.as_uint64_t &= ((((uint64_t) 1) << (wordLength << 3)) - 1);

    uint_fast64_t h = 14695981039346656037llu;
    h ^= state->word.as_uint64_t;
    h *= 1099511628211llu;
    uint_fast32_t xorfold = (uint_fast32_t) ((h >> 32) ^ h);
    uint_fast16_t shash = (uint_fast16_t) ((xorfold >> 16) ^ xorfold);

    ssc_argonaut_dictionary_secondary_entry *match = &state->dictionary.secondary_entry[shash];
    if (state->word.as_uint64_t != match->word.as_uint64_t) {
        if (match->durability)
            match->durability--;
        else {
            match->word.as_uint64_t = state->word.as_uint64_t;
        }
#ifdef SSC_ARGONAUT_ENCODE_PROCESS_LETTERS
        ssc_argonaut_encode_write_to_output(out, state, 0x1, 2);
        ssc_argonaut_encode_write_to_output(out, state, wordLength, 3);
        /*for (uint8_t i = 0; i < wordLength - 1; i += 2) {
            uint16_t diword = state->word.letters[i] + (((uint16_t)state->word.letters[i + 1]) << 8);
            ssc_argonaut_dictionary_tertiary_entry *m = &state->dictionary.tertiary_entry[diword];

            const uint16_t r = m->ranking;

            //const ssc_argonaut_huffman_code *huffmanCode = &ARGONAUT_NAME(hl).code[r];
            ssc_argonaut_encode_write_to_output(out, state, 0x12345678, 9);

            m->durability++;
            if (r) {
                const uint16_t pr = m->ranking - 1;
                ssc_argonaut_dictionary_tertiary_entry *pm = state->dictionary.ranking.tertiary[pr];
                if (unlikely(pm->durability < m->durability)) { // todo unlikely after a while
                    state->dictionary.ranking.tertiary[pr] = m;
                    state->dictionary.ranking.tertiary[r] = pm;
                    m->ranking -= 1;
                    pm->ranking += 1;
                }
            }
        }*/
        //uint_fast8_t rk = 0;
        //uint_fast8_t prev_rk = 0;
        //uint_fast8_t i;
        //const uint8_t limit = wordLength - 1;
        for (uint_fast8_t i = 0; i != wordLength; i ++) {
            *letter = state->word.letters[i];
            ssc_argonaut_dictionary_primary_entry *m = &state->dictionary.primary_entry[*letter];

            const uint_fast8_t rk = m->ranking;

            const ssc_argonaut_huffman_code *huffmanCode = &hl.code[rk];
            ssc_argonaut_encode_write_to_output(out, state, /*(uint32_t)*/huffmanCode->code, huffmanCode->bitSize);

            /*state->buffer += (huffmanCode->code << state->bufferBits);
            state->bufferBits += huffmanCode->bitSize;
            if(unlikely(state->bufferBits & ~0x1F)) {
                ssc_argonaut_encode_write_to_output(out, state, state->buffer, state->bufferBits);
                state->buffer = 0;
                state->bufferBits = 0;
            }*/

            /*if(i & 0x1) {
                const ssc_argonaut_huffman_code *huffmanCode = &ARGONAUT_NAME(h2l).code[(prev_rk << 8) + rk];
                ssc_argonaut_encode_write_to_output(out, state, huffmanCode->code, huffmanCode->bitSize);
            }*/
            
            m->durability++;
            if (ssc_likely(rk)) {
                const uint8_t pr = m->ranking - 1;
                ssc_argonaut_dictionary_primary_entry *pm = state->dictionary.ranking.primary[pr];
                if (ssc_unlikely(pm->durability < m->durability)) { // todo unlikely after a while
                    state->dictionary.ranking.primary[pr] = m;
                    state->dictionary.ranking.primary[rk] = pm;
                    m->ranking -= 1;
                    pm->ranking += 1;
                }
            }
            //prev_rk = rk;
        }
        /*if(!(i & 0x1)) {
            const ssc_argonaut_huffman_code *huffmanCode = &ARGONAUT_NAME(hl).code[rk];
            ssc_argonaut_encode_write_to_output(out, state, huffmanCode->code, huffmanCode->bitSize);
        }*/
        *separator = state->dictionary.ranking.primary[0]->letter;
#else
        ssc_argonaut_encode_write_to_output(out, state, 0x1, 2);
        ssc_argonaut_encode_write_to_output(out, state, wordLength, 3);
/*for (uint_fast8_t i = 0; i != wordLength; i ++) {
    *letter = state->word.letters[i];
    *(out->pointer + (out->position ++)) = *letter;
}*/
        *(uint64_t *) (out->pointer + out->position) = state->word.as_uint64_t;
        out->position += wordLength;
#endif
    } else {
//match->durability++;
        if (match->ranked) {
            const uint_fast8_t rk = match->ranking;
//state->bitCount += 2 + 8;
            ssc_argonaut_encode_write_to_output(out, state, 0x2, 2);
            ssc_argonaut_encode_write_to_output(out, state, rk, 8);
// todo dict code (3)
//ssc_argonaut_encode_write_coded(out, state, &ARGONAUT_NAME(ehl).code[SSC_ARGONAUT_ENTITY_RANKED_KEY]);
//ssc_argonaut_encode_write(out, state, 0, 2);
//ssc_argonaut_encode_write_coded(out, state, &ARGONAUT_NAME(shl).code[match->ranking]);
            match->durability++;
            if (rk) {
                const uint16_t preceding = rk - 1;
                ssc_argonaut_dictionary_secondary_entry *preceding_match = state->dictionary.ranking.secondary[preceding];
                if (preceding_match->durability < match->durability) {
                    state->dictionary.ranking.secondary[preceding] = match;
                    state->dictionary.ranking.secondary[rk] = preceding_match;
                    match->ranking -= 1;
                    preceding_match->ranking += 1;
                }
            }

        } else {
//state->bitCount += 2 + 16;
            ssc_argonaut_encode_write_to_output(out, state, 0x3, 2);
            ssc_argonaut_encode_write_to_output(out, state, shash, 16);
// todo dict code (2)
//ssc_argonaut_encode_write_coded(out, state, &ARGONAUT_NAME(ehl).code[SSC_ARGONAUT_ENTITY_KEY]);
//ssc_argonaut_encode_write(out, state, 0, encodeRanks ? 3 : 1);
//ssc_argonaut_encode_write(out, state, shash, 16);
            match->durability++;
//if (wordLength & ~0x1) {
            const uint16_t preceding = SSC_ARGONAUT_DICTIONARY_SECONDARY_RANKS - 1;
            ssc_argonaut_dictionary_secondary_entry *preceding_match = state->dictionary.ranking.secondary[preceding];
            if (preceding_match->durability < match->durability) {
                state->dictionary.ranking.secondary[preceding] = match;
                match->ranking = preceding;
                match->ranked = true;
                preceding_match->ranking = 0;
                preceding_match->ranked = false;
            }
//}
        }
    }

    state->word.length = 0;
//state->count --;

    return SSC_KERNEL_ENCODE_STATE_READY;
}

SSC_FORCE_INLINE SSC_KERNEL_ENCODE_STATE ssc_argonaut_encode_init(void *s) {
    ssc_argonaut_encode_state *state = s;
    //state->efficiencyChecked = 0;

    state->process = SSC_ARGONAUT_ENCODE_PROCESS_CHECK_OUTPUT_MEMORY;
    state->word.length = 0;
    //state->resetCycle = SSC_DICTIONARY_PREFERRED_RESET_CYCLE - 1;

    for (uint16_t i = 0; i < SSC_ARGONAUT_DICTIONARY_SECONDARY_RANKS; i++) {
        state->dictionary.ranking.secondary[i] = &state->dictionary.secondary_entry[i];
        state->dictionary.secondary_entry[i].ranking = (uint_fast8_t) i;
        state->dictionary.secondary_entry[i].ranked = true;
    }

    for (uint16_t i = 0; i < (1 << 8); i++)
        state->dictionary.primary_entry[i].letter = (uint8_t) (i);

    for (uint16_t i = 0; i < SSC_ARGONAUT_DICTIONARY_PRIMARY_RANKS; i++) {
        state->dictionary.ranking.primary[i] = &state->dictionary.primary_entry[i];
        state->dictionary.primary_entry[i].ranking = (uint8_t) i;
    }

    return SSC_KERNEL_ENCODE_STATE_READY;
}

SSC_FORCE_INLINE SSC_KERNEL_ENCODE_STATE ssc_argonaut_encode_process(ssc_byte_buffer *restrict in, ssc_byte_buffer *restrict out, void *restrict s, const ssc_bool flush) {
    ssc_argonaut_encode_state *state = s;
    SSC_KERNEL_ENCODE_STATE returnState;
    uint_fast8_t letter;
    uint_fast32_t hash = 0;

#ifdef SSC_ARGONAUT_ENCODE_PROCESS_LETTERS
    uint8_t separator = state->dictionary.ranking.primary[0]->letter;
#else
    uint8_t separator = 0x20;
#endif

    if (in->size == 0)
        goto exit;

    switch (state->process) {
        /*case SSC_ARGONAUT_ENCODE_PROCESS_CHECK_STATE:
            if ((returnState = ssc_argonaut_encode_check_state(out, state)))
                return returnState;
            state->process = SSC_ARGONAUT_ENCODE_PROCESS_GOTO_NEXT_WORD;
            break;*/

        case SSC_ARGONAUT_ENCODE_PROCESS_CHECK_OUTPUT_MEMORY:
        check_mem:
            if ((returnState = ssc_argonaut_encode_prepare_new_block(out, state, BLOCK * 32)))
                return returnState;
            state->process = SSC_ARGONAUT_ENCODE_PROCESS_GOTO_NEXT_WORD;
            //break;
            /*case SSC_ARGONAUT_ENCODE_PROCESS_PREPARE_OUTPUT:
                ssc_argonaut_encode_prepare_next_output_unit_even(out, state);
                state->process = SSC_ARGONAUT_ENCODE_PROCESS_GOTO_NEXT_WORD;*/

        case SSC_ARGONAUT_ENCODE_PROCESS_GOTO_NEXT_WORD:
        next_word:
            returnState = ssc_argonaut_encode_find_next_word(in, out, state, &separator);
            if (returnState) {
                if (flush) {
                    if (returnState == SSC_KERNEL_ENCODE_STATE_STALL_ON_INPUT_BUFFER) {
                        state->process = SSC_ARGONAUT_ENCODE_PROCESS_FINISH;
                        return SSC_KERNEL_ENCODE_STATE_READY;
                    }
                } else
                    return returnState;
            }/* else if(unlikely(!state->count)) {
                state->process = SSC_ARGONAUT_ENCODE_PROCESS_CHECK_OUTPUT_MEMORY;
                goto check_mem;
            }*/
            //state->process = SSC_ARGONAUT_ENCODE_PROCESS_CHECK_AVAILABLE_MEMORY;
            state->process = SSC_ARGONAUT_ENCODE_PROCESS_WORD;
            //break;

            /*case SSC_ARGONAUT_ENCODE_PROCESS_CHECK_AVAILABLE_MEMORY:
                if ((returnState = ssc_argonaut_encode_check_next_output_block_memory_available(out, state)))
                    return returnState;
                state->process = SSC_ARGONAUT_ENCODE_PROCESS_WORD;*/

        case SSC_ARGONAUT_ENCODE_PROCESS_WORD:
            returnState = ssc_argonaut_encode_process_word(in, out, &letter, &hash, state, &separator);
            if (returnState) {
                if (flush) {
                    if (returnState == SSC_KERNEL_ENCODE_STATE_STALL_ON_INPUT_BUFFER) {
                        state->process = SSC_ARGONAUT_ENCODE_PROCESS_FINISH;
                        return SSC_KERNEL_ENCODE_STATE_READY;
                    }
                } else
                    return returnState;
            }/* else if(unlikely(!state->count)) {
                state->process = SSC_ARGONAUT_ENCODE_PROCESS_CHECK_OUTPUT_MEMORY;
                goto check_mem;
            }*/
            state->process = SSC_ARGONAUT_ENCODE_PROCESS_GOTO_NEXT_WORD;
            if (ssc_likely(--state->count))
                goto next_word;
            else
                goto check_mem;

        case SSC_ARGONAUT_ENCODE_PROCESS_FINISH:
            //printf("%llu\n", state->bitCount >> 3);
            //for (uint32_t i = 0; i < (1 << 8); i++)
            //    printf("%c\t%u\t%u\n", state->dictionary.ranking.primary[i]->letter, state->dictionary.ranking.primary[i]->durability, state->dictionary.ranking.primary[i]->ranking);
        exit:
            state->process = SSC_ARGONAUT_ENCODE_PROCESS_GOTO_NEXT_WORD;
            return SSC_KERNEL_ENCODE_STATE_FINISHED;

        default:
            return SSC_KERNEL_ENCODE_STATE_ERROR;
    }
}

SSC_FORCE_INLINE SSC_KERNEL_ENCODE_STATE ssc_argonaut_encode_finish(void *s) {
    //ssc_argonaut_encode_state *state = s;

    return SSC_KERNEL_ENCODE_STATE_READY;
}