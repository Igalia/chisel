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

<!-- vim: filetype=markdown spell spelllang=en
  -->
