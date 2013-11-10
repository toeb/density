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

const ssc_argonaut_primary_code_lookup ssc_argonaut_letter_coding = {.code = SSC_ARGONAUT_PRIMARY_HUFFMAN_CODES};

SSC_FORCE_INLINE SSC_KERNEL_ENCODE_STATE ssc_argonaut_encode_prepare_new_block(ssc_byte_buffer *restrict out, ssc_argonaut_encode_state *restrict state, const uint_fast32_t minimumLookahead) {
    out->position += (state->shift >> 3);
    state->shift &= 0x7llu;
    if (out->position + minimumLookahead > out->size)
        return SSC_KERNEL_ENCODE_STATE_STALL_ON_OUTPUT_BUFFER;
    state->count = SSC_ARGONAUT_BLOCK;

    return SSC_KERNEL_ENCODE_STATE_READY;
}

SSC_FORCE_INLINE void ssc_argonaut_encode_write_to_output(ssc_byte_buffer *restrict out, ssc_argonaut_encode_state *state, const uint_fast32_t value, const uint_fast8_t bitSize) {
#if __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
    *(uint_fast32_t *) (out->pointer + out->position + (state->shift >> 3)) += ((/*(uint_fast64_t)*/ value) << (state->shift & 0x7)); // 18 bits max << 8 = 26
#elif __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
    *(state->output) |= value << ((56 - (state->shift & ~0x7)) + (state->shift & 0x7));
#endif
    state->shift += bitSize;
}

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
        state->shift += 2;
        state->dictionary.ranking.primary[0]->durability++;
        in->position++;
        if (ssc_unlikely(in->position == in->size))
            return SSC_KERNEL_ENCODE_STATE_STALL_ON_INPUT_BUFFER;
    }

    return SSC_KERNEL_ENCODE_STATE_READY;
}

SSC_FORCE_INLINE SSC_KERNEL_ENCODE_STATE ssc_argonaut_encode_process_word(ssc_byte_buffer *restrict in, ssc_byte_buffer *restrict out, uint_fast8_t *letter, uint_fast32_t *restrict hash, ssc_argonaut_encode_state *restrict state, uint8_t *separator) {
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

    uint_fast64_t hash64 = 14695981039346656037llu;
    hash64 ^= state->word.as_uint64_t;
    hash64 *= 1099511628211llu;
    uint_fast32_t xorfold32 = (uint_fast32_t) ((hash64 >> 32) ^ hash64);
    uint_fast16_t hash16 = (uint_fast16_t) ((xorfold32 >> 16) ^ xorfold32);

    ssc_argonaut_dictionary_secondary_entry *match = &state->dictionary.secondary_entry[hash16];
    if (state->word.as_uint64_t != match->word.as_uint64_t) {
        if (match->durability)
            match->durability--;
        else {
            match->word.as_uint64_t = state->word.as_uint64_t;
        }
        ssc_argonaut_encode_write_to_output(out, state, SSC_ARGONAUT_ENTITY_PLAIN_WORD, 2);
        ssc_argonaut_encode_write_to_output(out, state, wordLength, 3);

        for (uint_fast8_t i = 0; i != wordLength; i ++) {
            *letter = state->word.letters[i];
            ssc_argonaut_dictionary_primary_entry *letterMatch = &state->dictionary.primary_entry[*letter];

            const uint_fast8_t rank = letterMatch->ranking;

            const ssc_argonaut_huffman_code *huffmanCode = &ssc_argonaut_letter_coding.code[rank];
            ssc_argonaut_encode_write_to_output(out, state, huffmanCode->code, huffmanCode->bitSize);

            letterMatch->durability++;
            if (ssc_likely(rank)) {
                const uint8_t precedingRank = letterMatch->ranking - 1;
                ssc_argonaut_dictionary_primary_entry *precedingRankLetter = state->dictionary.ranking.primary[precedingRank];
                if (ssc_unlikely(precedingRankLetter->durability < letterMatch->durability)) { // todo unlikely after a while
                    state->dictionary.ranking.primary[precedingRank] = letterMatch;
                    state->dictionary.ranking.primary[rank] = precedingRankLetter;
                    letterMatch->ranking -= 1;
                    precedingRankLetter->ranking += 1;
                }
            }
        }
        *separator = state->dictionary.ranking.primary[0]->letter;
    } else {
        if (match->ranked) {
            const uint_fast8_t rank = match->ranking;
            ssc_argonaut_encode_write_to_output(out, state, SSC_ARGONAUT_ENTITY_WORD_RANK, 2);
            ssc_argonaut_encode_write_to_output(out, state, rank, 8);
            match->durability++;
            if (rank) {
                const uint16_t preceding = rank - 1;
                ssc_argonaut_dictionary_secondary_entry *preceding_match = state->dictionary.ranking.secondary[preceding];
                if (preceding_match->durability < match->durability) {
                    state->dictionary.ranking.secondary[preceding] = match;
                    state->dictionary.ranking.secondary[rank] = preceding_match;
                    match->ranking -= 1;
                    preceding_match->ranking += 1;
                }
            }

        } else {
            ssc_argonaut_encode_write_to_output(out, state, SSC_ARGONAUT_ENTITY_WORD_HASH, 2);
            ssc_argonaut_encode_write_to_output(out, state, hash16, 16);
            match->durability++;
            const uint16_t preceding = SSC_ARGONAUT_DICTIONARY_SECONDARY_RANKS - 1;
            ssc_argonaut_dictionary_secondary_entry *preceding_match = state->dictionary.ranking.secondary[preceding];
            if (preceding_match->durability < match->durability) {
                state->dictionary.ranking.secondary[preceding] = match;
                match->ranking = preceding;
                match->ranked = true;
                preceding_match->ranking = 0;
                preceding_match->ranked = false;
            }
        }
    }

    state->word.length = 0;

    return SSC_KERNEL_ENCODE_STATE_READY;
}

SSC_FORCE_INLINE SSC_KERNEL_ENCODE_STATE ssc_argonaut_encode_init(void *s) {
    ssc_argonaut_encode_state *state = s;

    state->process = SSC_ARGONAUT_ENCODE_PROCESS_CHECK_OUTPUT_MEMORY;
    state->word.length = 0;

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

    uint8_t separator = state->dictionary.ranking.primary[0]->letter;

    if (in->size == 0)
        goto exit;

    switch (state->process) {
        case SSC_ARGONAUT_ENCODE_PROCESS_CHECK_OUTPUT_MEMORY:
        check_mem:
            if ((returnState = ssc_argonaut_encode_prepare_new_block(out, state, SSC_ARGONAUT_BLOCK * 32)))
                return returnState;
            state->process = SSC_ARGONAUT_ENCODE_PROCESS_GOTO_NEXT_WORD;

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
            }
            state->process = SSC_ARGONAUT_ENCODE_PROCESS_WORD;

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
            }
            state->process = SSC_ARGONAUT_ENCODE_PROCESS_GOTO_NEXT_WORD;
            if (ssc_likely(--state->count))
                goto next_word;
            else
                goto check_mem;

        case SSC_ARGONAUT_ENCODE_PROCESS_FINISH:
        exit:
            state->process = SSC_ARGONAUT_ENCODE_PROCESS_GOTO_NEXT_WORD;
            return SSC_KERNEL_ENCODE_STATE_FINISHED;

        default:
            return SSC_KERNEL_ENCODE_STATE_ERROR;
    }
}

SSC_FORCE_INLINE SSC_KERNEL_ENCODE_STATE ssc_argonaut_encode_finish(void *s) {
    return SSC_KERNEL_ENCODE_STATE_READY;
}