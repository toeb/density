/*
 * Centaurean Density
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
 * 11/10/13 02:01
 */

#ifndef DENSITY_GLOBALS_H
#define DENSITY_GLOBALS_H

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
//#include <unistd.h>
#include <stddef.h>

#if defined(__INTEL_COMPILER)
#define DENSITY_FORCE_INLINE __forceinline
#elif defined(_MSC_VER)
#define restrict
#define DENSITY_FORCE_INLINE __forceinline
#elif defined(__GNUC__)
#define DENSITY_FORCE_INLINE inline __attribute__((always_inline))
#elif defined(__clang__)
#define DENSITY_FORCE_INLINE inline __attribute__((always_inline))
#else
#warning Impossible to force functions inlining. Expect performance issues.
#endif

#if __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
#define DENSITY_LITTLE_ENDIAN_64(b)   ((uint64_t)b)
#define DENSITY_LITTLE_ENDIAN_32(b)   ((uint32_t)b)
#define DENSITY_LITTLE_ENDIAN_16(b)   ((uint16_t)b)
#elif __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#if __GNUC__ * 100 + __GNUC_MINOR__ >= 403
#define DENSITY_LITTLE_ENDIAN_64(b)   __builtin_bswap64(b)
#define DENSITY_LITTLE_ENDIAN_32(b)   __builtin_bswap32(b)
#define DENSITY_LITTLE_ENDIAN_16(b)   __builtin_bswap16(b)
#else
#warning Using bulk byte swap routines. Expect performance issues.
#define DENSITY_LITTLE_ENDIAN_64(b)   ((((b) & 0xFF00000000000000ull) >> 56) | (((b) & 0x00FF000000000000ull) >> 40) | (((b) & 0x0000FF0000000000ull) >> 24) | (((b) & 0x000000FF00000000ull) >> 8) | (((b) & 0x00000000FF000000ull) << 8) | (((b) & 0x0000000000FF0000ull) << 24ull) | (((b) & 0x000000000000FF00ull) << 40) | (((b) & 0x00000000000000FFull) << 56))
#define DENSITY_LITTLE_ENDIAN_32(b)   ((((b) & 0xFF000000) >> 24) | (((b) & 0x00FF0000) >> 8) | (((b) & 0x0000FF00) << 8) | (((b) & 0x000000FF) << 24))
#define DENSITY_LITTLE_ENDIAN_16(b)   ((((b) & 0xFF00) >> 8) | (((b) & 0x00FF) << 8))
#endif
#else
#error Unknow endianness
#endif

#define DENSITY_DICTIONARY_PREFERRED_RESET_CYCLE_SHIFT    6
#define DENSITY_DICTIONARY_PREFERRED_RESET_CYCLE          (1 << DENSITY_DICTIONARY_PREFERRED_RESET_CYCLE_SHIFT)

#define density_likely(x)                         __builtin_expect(!!(x), 1)
#define density_unlikely(x)                       __builtin_expect(!!(x), 0)

#define density_bitsizeof(x) (8 * sizeof(x))


/**********************************************************************************************************************
 *                                                                                                                    *
 * Global compile-time switches                                                                                       *
 *                                                                                                                    *
 **********************************************************************************************************************/

#define DENSITY_YES 1
#define DENSITY_NO  0

#define DENSITY_MAJOR_VERSION   0
#define DENSITY_MINOR_VERSION   12
#define DENSITY_REVISION        1

/*
 * Compile-time switches useful for pure data encoding and decoding
 * They enable/disable writing of the main headers and footers
 */
#define DENSITY_WRITE_MAIN_HEADER   DENSITY_YES
#define DENSITY_WRITE_MAIN_FOOTER   DENSITY_YES

/*
 * If set to yes, created output's decompression is parallelizable.
 * If set to no, compression dictionary resets are disabled and therefore compression ratio is improved
 */
#define DENSITY_ENABLE_PARALLELIZABLE_DECOMPRESSIBLE_OUTPUT DENSITY_NO



#endif
