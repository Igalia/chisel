# Chisel - Braille embosser filters

Chisel is a Free Software set of tools and filters to use Braille embossers
in Unix systems. Most of the time it is used in conjunction with
[CUPS](http://cups.org).

## Installation

1. *(Optional)* Edit `Makefile.config` to suit your needs.
2. `make`
3. `make install`

Also, you may want to set the installation prefix by passing `PREFIX=/usr`
(or any other path) to the Make invocation.

Packagers may want to pass `DESTDIR=/path/to/tmpdir` in the installation
step, to perform installation in an alternative file system root.

## Basic usage

### Obtaining information

The following command can be used to list the available devices:

    chisel -S chisel-ppd list simple

(Changing `simple` to `plain` will list only first column with the device
identifiers.)

A PostScript Printer Definition (PPD) file to be used with other printing
systems like CUPS is can be obtained by providing the device identifier
to the following command:

    chisel -S chisel-ppd cat device-id > file.ppd

### Rendering a document

Provided that a file is already in the [Chisel device-independent
document format](docformat.md.html) (examples can be found under the
`doc/examples/` subdirectory), the next command can be used to render
it into a raw stream of data that can be then sent to the device. For
example for an Index Braille Basic-D device:

    chisel -S chiseltodev device=indexbraille/basic-d \
      < input.chsl > output.raw

Then, supposing that the embosser device is the `/dev/lp0` device, it
can be sent directly to it:

    cat output.raw > /dev/lp0

or even directly using the device as output for the command above:

    chisel -S chiseltodev device=indexbraille/basic-d \
      < input.chsl > /dev/lp0

The raw output files contain all the information that a *particular
device model* needs to know to properly emboss a document. Note that
raw *output generated for one device cannot be used for another which
is a different model*.

<!-- vim: filetype=markdown spell spelllang=en
  -->
