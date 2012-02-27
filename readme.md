# Introduction

Chisel is a Free Software set of tools and filters to use Braille embossers
in Unix systems. Most of the time it is used in conjunction with
[CUPS](http://cups.org).


# Architecture

## Driver filter

## Conversion filters

All the included filters convert their input to the Chisel [device-independent
document format](@Document_format). The following filters are provided:

* `texttochisel`: Converts plain text.


# Document format

Ultimately, the [driver](#Driver_filter) accepts only a particular input
format, which describes a document in an abstract, device-independent way.
The various [filters](#Conversion_filters) provided convert popular formats
to the device-independent document format used by Chisel. This section
describes that document format. Examples can be found under `doc/examples`
in the distribution directory.

<!-- vim: filetype=markdown spell spelllang=en
  -->
