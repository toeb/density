#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>

#include "density_api.h"

#define TEXT "--APPLE II HISTORY\n"\
"===== == =======\n"\
"\n"\
"Compiled and written by Steven Weyhrich\n"\
"(C) Copyright 1991, Zonker Software\n"\
"\n"\
"(PART 1 -- PRE-APPLE HISTORY)\n"\
"[v1.1 :: 12 Dec 91]\n"\
"\n"\
"\n"\
"INTRODUCTION\n"\
"\n"\
"     This project began as a description of how the Apple II evolved into a IIGS, and some of the standards that emerged along the way.  It has grown into a history of Apple Computer, with an emphasis on the place of the Apple II in that history.  It has been gleaned from a variety of magazine articles and books that I have collected over the years, supplemented by information supplied by individuals who were \"there\" when it happened.  I have tried not to spend much time on information that has been often repeated, but rather on the less known stories that led to the Apple II as we know it (and love it) today.  Along the way I hope to present some interesting technical trivia, some thoughts about what the Apple II could have been, and what the Apple II still can be.  The Apple II has been described as the computer that refuses to die.  This story tells a little bit of why that is true.\n"\
"\n"\
"     If you are a new Apple II owner in 1991 and use any 8-bit Apple II software at all, you may feel bewildered by the seemingly nonsensical way in which certain things are laid out.  AppleWorks asks which \"slot\" your printer is in.  If you want to use the 80 column screen in Applesoft BASIC you must type an odd command, \"PR#3\".  If you want to write PROGRAMS for Applesoft, you may have some of those ridiculous PEEKs and POKEs to contend with.  The disk layout (which type is supposed to go into which slot) seems to be in some random order!  And then there is the alphabet soup of disk systems: DOS 3.3, CP/M, Pascal, ProDOS, and GS/OS (if you have a IIGS).  If you use 16-bit software EXCLUSIVELY, you will probably see none of this; however, even the most diehard GS user of the \"latest and greatest\" 16-bit programs will eventually need to use an 8-bit program.  If you can tolerate a history lesson and would like to know \"the rest of the story,\" I will try to make sense of it all.\n"\
"\n"\
"     I think one of the Apple II's greatest strengths is the attention they have paid over the years to be backward compatible.  That means that a IIGS \"power system\" manufactured in 1991, with 8 meg of memory, a hand-held optical scanner, CD-ROM drive, and 150 meg of hard disk storage can still run an Integer BASIC program written in 1977, probably without ANY modification!  In the world of microcomputers, where technology continues to advance monthly, and old programs may or may not run on the new models, that consistency is amazing to me.  Consider the quantum leap in complexity and function between the original 4K Apple ][ and the ROM 03 IIGS; the amount of firmware (built-in programs) in the IIGS is larger than the entire RAM SPACE in a fully expanded original Apple ][!\n"\
"     This strength of the Apple II could also be considered a weakness, because it presents a major difficulty in making design improvements that keep up with the advances in computer technology between 1976 and the present, and yet maintain that compatibility with the past.  Other early computer makers found it easy to design improvements that created a better machine, but they did so at the expense of their existing user base (Commodore comes to mind, with the PET, Vic 20, Commodore 64, and lastly the Amiga, all completely incompatible).  However, this attention to detail is just one of the things that has made the Apple II the long-lived computer that it is.\n"\
"     In examining the development of the Apple II, we will take a look at some pre-Apple microcomputer history, the Apple I, and the formation of Apple Computers, Inc., with some sideroads into ways in which early users overcame the limits of their systems.  We will follow through with the development of the Apple IIe, IIc, and IIGS, and lastly make some comments on the current state of affairs at Apple Inc. regarding the Apple II.\n"\
"\n"\
"\n"\
"PRE-APPLE HISTORY\n"\
"\n"\
"     Let's begin our adventure in history.  I've designed a special interface card that plugs into slot 7 on an Apple II.  It contains an item its inventor called a \"Flux Capacitor\" (something about the being able to modify flux and flow of time).  The card derives its power from a self-contained generator called \"Mr. Fusion\" (another item I dug out of the wreckage from a train/auto accident in California a couple of years ago). Connected to the card via a specially shielded line, Mr. Fusion runs on trash (and is, therefore, the ultimate computer peripheral, if you recall the old principal of \"garbage in, garbage out\").  Let's put a few issues of PC MAGAZINE into Mr. Fusion, and switch on the Flux Capacitor. (Incidentally, for this to work, it needs an Apple II equipped with a specially modified Zip chip running at 88 MHz).  Boot the disk and set the time circuits for 1975.  Ready?  Set?  Go!  ** CRACKADOOM ** !!\n"\
"\n"\
"     Did you make it all right?  (Just don't touch anything -- you don't want to disrupt the space-time continuum, you know!)  Now, since the first Apple II wasn't released until 1977, what are we doing back in 1975?  Well, to understand how the Apple II came about, it helps to know the environment that produced it.  In 1975, the microcomputer industry was still very much in its infancy.  There were few \"home computers\" that you can choose from, and their capabilities were very much limited.  The first microprocessor chip, the 4-bit 4004, had been released by Intel back in 1971.  The first video game, Pong, was created by Nolan Bushnell of Atari in 1972.  Also in 1972, Intel had gone a step further in microprocessor development and released the 8-bit 8008, and then the 8080 in 1973.  The year 1974 saw Scelbi Computer Consulting sell what some consider to be the first commercially built microcomputer, the Scelbi 8-H, based on Intel's 8008 chip.  However, it had limited distribution and due to the designer's health problems it didn't go very far.  The first home-built computer, the Mark 8, was released that same year.  The Mark 8 used the Intel 8080 chip, but had no power supply, monitor, keyboard, or case, and only a few hobbyists ever finished their kits.  Overall, the microchip had yet to make much of an impact on the general public beyond the introduction of the hand-held calculator.\n"\
"     With the start of 1975 came a significant event in microcomputer history.  If you will consider the early microprocessors of the years 1971 through 1974 as a time of germination and \"pregnancy\" of ideas and various hardware designs, January of 1975 saw the \"labor and delivery\" of a special package.  The birth announcement was splashed on the front cover of a hacker's magazine, Popular Electronics.  The baby's parents, MITS, Inc., named it \"Altair 8800\"; it measured 18-inches deep by 17 inches wide by 7 inches high, and it weighed in at a massive 256 bytes (that's one fourth of a \"K\").  Called the \"World's First Minicomputer Kit to Rival Commercial Models,\" the Altair 8800 used the Intel 8080 chip, and sold for $395 (or $498 fully assembled).  MITS hoped that they would get about four hundred orders for clones of this baby, trickling in over the months that the two-part article was printed.  This would supply the money MITS needed to buy the parts to send to people ordering the kits (one common way those days of \"bootstrapping\" a small electronics business).  This \"trickle\" of orders would also give MITS time to establish a proper assembly line for packaging the kits.  However, they misjudged the burning desire of Popular Electronic's readers to build and operate their own computer.  MITS received four hundred orders in ONE AFTERNOON, and in three weeks it had taken in $250,000.<1>\n"\
"     The Popular Electronics article was a bit exuberant in the way the Altair 8800 was described.  They called it \"a full-blown computer that can hold its own against sophisticated minicomputers now on the market... The Altair 8800 is not a 'demonstrator' or souped-up calculator... [it] is a complete system.\"  The article had an insert that lists some possible applications for the computer, stating that \"the Altair 8800 is so powerful, in fact, that many of these applications can be performed simultaneously.\"  Among the possible uses listed are an automated control for a ham station, a digital clock with time zone conversion, an autopilot for planes and boats, navigation computer, a brain for a robot, a pattern-recognition device, and a printed matter-to-Braille converter for the blind.<2>  Many of these things will be possible with microcomputers by 1991, but even by then few people will have the hardware add-ons to make some of these applications possible.  Also, despite the power that micros will have in that year, the ability to carry out more than one of these applications \"simultaneously\" will not be not practical or in some cases even possible.  The exaggeration by the authors of the Popular Electronics article can perhaps be excused by their excitement in being able to offer a computer that ANYONE can own and use.  All this was promised from a computer that came \"complete\" with only 256 bytes of memory (expandable if you can afford it) and no keyboard, monitor, or storage device.\n"\
"     The IMSAI 8080 (an Altair clone) also came out in 1975 and did fairly well in the hobbyist market.  Another popular early computer, the Sol, would not be released until the following year.  Other computers released in 1975 that enjoyed limited success were the Altair 680 (also from MITS, Inc., based on the Motorola 6800 processor), the Jupiter II (Wavemate), M6800 (Southwest Technical Products), and the JOLT (Microcomputer Associates), all kits.<3>  The entire microcomputer market was still very much a hobbyist market, best suited for those who enjoyed assembling a computer from a kit.  After you assembled your computer, you either had to write your own programs (from assembly language) or enter a program someone else wrote.  If you could afford the extra memory and the cost of buying a BASIC interpreter, you might have been able to write some small programs that ran in that language instead of having to figure out 8080 assembly language.  If you were lucky (or rich) you had 16K of memory, possibly more; if you were REALLY lucky you owned (or could borrow) a surplus paper tape reader to avoid typing in manually your friend's checkbook balancing program.  Did I say typing?  Many early computer hobbyists didn't even have the interface allowing them to TYPE from a keyboard or teletype.  The \"complete\" Altair 8800 discussed above could only be programmed by entering data via tiny little switches on its front panel, as either octal (base 8) bytes or hexadecimal (base 16) bytes.  With no television monitor available either, the results of the program were read in binary (base 2) from lights on that front panel.  This may sound like the old story that begins with the statement, \"I had to walk five miles to school through snow three feet deep when I was your age,\" but it helps to understand how things were at this time to see what a leap forward the Apple II really was (er, will be. Time travel complicates grammar!)\n"\
"\n"\
"++++++++++++++++++++++++++++++\n"\
"\n"\
"NEXT INSTALLMENT:  The Apple I\n"\
"\n"\
"++++++++++++++++++++++++++++++\n"\
"\n"\
"NOTES\n"\
"\n"\
"     <1> Steven Levy, HACKERS: HEROES OF THE COMPUTER REVOLUTION, pp. 187-192.\n"\
"\n"\
"     <2> H. Edward Roberts and William Yates, \"Altair 8800 Minicomputer, Part 1\", POPULAR ELECTRONICS, January 1975, pp. 33, 38.  The article is interesting also in some of the terminology that is used.  The Altair is described as having \"256 eight-bit words\" of RAM.  Apparently, the term \"byte\" was not in common use yet.\n"\
"\n"\
"     <3> Gene Smarte and Andrew Reinhardt, \"15 Years of Bits, Bytes, and Other Great Moments\", BYTE, September 1990, pp. 370-371.\n"

#define BUFFER_SIZE    DENSITY_MINIMUM_OUT_BUFFER_SIZE

int main(int argc, char *argv[]) {
    printf("Text length : %ld\n", strlen(TEXT));
    uint8_t *outCompressed = (uint8_t *) malloc(BUFFER_SIZE * sizeof(uint8_t));
    uint8_t *outDecompressed = (uint8_t *) malloc(BUFFER_SIZE * sizeof(uint8_t));

    density_buffer_processing_result result;
    result = density_buffer_compress((uint8_t *) TEXT, strlen(TEXT), outCompressed, BUFFER_SIZE, DENSITY_COMPRESSION_MODE_LION_ALGORITHM, DENSITY_BLOCK_TYPE_DEFAULT, NULL, NULL);
    if (result.state == DENSITY_BUFFER_STATE_OK)
        printf("%llu bytes >> %llu bytes\n", result.bytesRead, result.bytesWritten);
    else
        fprintf(stderr, "Error %i occured during compression\n", result.state);

    result = density_buffer_decompress(outCompressed, result.bytesWritten, outDecompressed, BUFFER_SIZE, NULL, NULL);
    if (result.state == DENSITY_BUFFER_STATE_OK)
        printf("%llu bytes >> %llu bytes\n", result.bytesRead, result.bytesWritten);
    else
        fprintf(stderr, "Error %i occured during decompression\n", result.state);

    for (int i = 0; i < result.bytesWritten; i++) {
        printf("%c", outDecompressed[i]);
    }

    free(outCompressed);
    free(outDecompressed);

    return 0;
}