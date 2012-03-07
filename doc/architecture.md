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
to the device-independent [document format](docformat.md.html) used by
Chisel. Examples can be found under `doc/examples` in the distribution
directory. The MIME type is `application/x-chisel-text`.

<!-- vim: filetype=markdown spell spelllang=en
  -->
