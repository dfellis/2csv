# 2csv
is a collection of small Perl utilities I wrote during my PhD for data processing. I am MIT licensing in case anyone else finds them useful (such as my labmates).

## dcplt2csv
converts the HP4156 sweep-mode file data (.plt) into CSV

## plt2csv
is a hybrid that handles the HP4156 sweep-mode file data, as well as the Sentaurus simulation suite's .plt format into CSV

## tlp2csv
converts Barth Electronic's .tlp format into CSV (for both the 4002 and 4012 models, which differ slightly)

## twf2csv
converts Barth Electronics's .twf format into CSV (also works for both models, but only useful for the 4012 because it makes no pretenses at separating the overlapping pulses in the 4002's input data)

## twf2tlp
not technically a converter to CSV, but useful in conjunction with it. The .tlp format is just a "summary" of the data in the .twf format, performing an averaging of voltage and current data during an averaging window specified by the user. This utility makes it easy to reprocess the .twf data for alternate windows, if desired.

## twfmanip
performs more complex analyses on the data in the .twf file, producing csv data on Power or Energy versus time for a single pulse, average power or total energy for each pulse, voltage and current derivatives versus time, and so on.

## txt2csv
converts the HP4156 sampling-mode file data (.txt) into CSV

# License (MIT)

Copyright (C) 2008-2011 by David Ellis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
