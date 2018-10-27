On October 26th, 2018 I purchased the software assets of Full Moon Software.
Full Moon Software used to be known as Crescent Software.  They produced a line
of excellent development libraries for MS-DOS.  The supported environments were
QuickBASIC 4.x, Microsoft Professional Development System v7.x, and Visual 
Basic for DOS.

The idea behind obtaining these products was to release them to the public
domain to ensure that people could still access these things in the future.
While most developers will have no use for these products in a modern 
develoment environment, they still have value as an example of "how it was 
done" back in the heyday of x86 DOS development. 

The software in this repository hasn't been modified from how I received it 
from Ethan Winer, the original author.  While all the source files carry some 
kind of Copyright notice, the software is now in the public domain.

The contents of the installation floppies will be uploaded to the Internet
Archive soon and when the manuals are scanned, they'll be uploaded there
as well.  I'll update this readme file with a link to the manual scan when
it's available.

The original distribution disk files are available here:

http://annex.retroarchive.org/crescent/CWSHDISK.ZIP


Gene Buckle, October 27th, 2018

I've attached the text from Full Moon Software's catalog description of 
Compression Workshop below.

-------------------------------------------------------------------------------
=============================================================================

THE COMPRESSION WORKSHOP(tm)
============================

Routines to Compress and Decompress Data
----------------------------------------

The Compression Workshop is a collection of subroutines and functions for 
compressing and decompressing array, string, file, and video memory data. 
Several complete programs are provided, including a full-featured Install 
utility you can use to distribute your own applications in compressed form, 
and also a disk backup and restore program that can be added to your programs 
or used stand-alone.
     The compression and decompression routines are designed for use with 
arrays, strings, and files. Numeric, TYPE, and fixed-length string arrays may 
be stored in compressed form on disk, either individually or in groups within 
a single file. One or more program or data files may also be combined into a 
single compressed file. Arrays may be compressed either in place (within 
memory) or stored in a disk file. When storing an array in a file, you 
indicate if the file is to be created, or if the array is to be added to an 
existing compressed file. Likewise, array data may be decompressed in place or 
read from disk. When compressing an array in memory, the compressed data 
replaces the original array contents, and the array is redimensioned to the 
new, smaller size automatically.
     Separate routines are provided to manipulate data in memory and on disk. 
Individual strings may be compressed and decompressed in place only, and the 
result is assigned to the same string. Video memory may be copied to an array 
using supplied routines and then compressed and optionally stored on disk. A 
compressed file that holds other files (not one that holds arrays) may 
optionally be converted to a self-extracting .EXE program that unpacks itself 
when run, placing all of the files it contains into the current directory or 
any specified directory.
     Finally, several complete demonstration programs are provided to show how 
the various Compression Workshop routines are used. These include utilities 
for compressing and decompressing groups of files based on command line 
options; an Install program that supports multiple distribution disks with 
separate target paths for all the files within each compressed file; and a 
stand-alone hard disk backup program that also shows how the backup and 
restore routines are added to your own programs. The backup and restore 
routines feature automatic disk formatting, volume labeling, traversing nested 
subdirectory levels, and they can optionally manipulate each file's archive 
bit. They can also automatically detect when a disk is changed, making them 
very easy for your customers to use.

THE FULL MOON PHILOSOPHY

As with all our products, full source code is provided at no additional cost, 
so you can see how the routines were designed and even modify them if you 
want. We genuinely want you to understand how our libraries work and be able 
to learn from them. All of our products are reasonably priced and include free 
technical assistance, but they are licensed for use by only one person using 
one computer at a time. Royalty payments are not required when our routines 
are incorporated into your compiled applications. However, you may not 
distribute our source, object, or library files. If your customers need to 
rebuild your program, they will need their own copy of our product(s).

THE BOTTOM LINE

The Compression Workshop costs $149 and works with QuickBASIC 4.x, PDS 7.x, 
and VB/DOS. Add $8 for UPS ground shipping to US addresses only (no P.O. 
boxes); Connecticut residents must add 6.0% sales tax or show proof of tax-
exempt status when ordering. Please call for overnight and foreign shipping 
costs. We accept checks, MasterCard, and VISA. We do accept purchase orders, 
but they must be accompanied by full payment.

Compression Workshop(tm) is a trademark of Crescent Software, Inc.
