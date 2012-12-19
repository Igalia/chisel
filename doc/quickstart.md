# Chisel Quick Start Guide

Chisel is a set of Free Software tools and filters to use braille embossers
in Unix systems. Most of the time it is used in conjunction with
[CUPS](http://cups.org).

The purpose of this document is to provide a high-level, end-user
introduction to Chisel. Those interested in command line usage,
a description of the Chisel device independent document format and other
low-level management details should consult Chisel's documentation.

# Step 0: Getting the CUPS filters and the PPD files

The average users would like to install and send jobs to their braille
embosser as they would any other printer. On Linux, the most common way to
interact with printers is by using CUPS. Chisel provides the CUPS filters
necessary for interacting with braille embossers, and the way to obtain
a PPD file (PostScript Printer Description) in order to install them.

Your distribution may provide all of the packages you need. If this is not
the case, or if you would like to install a more recent version of Chisel,
you should do the following:

a. Install CUPS if it is not already installed.
b. Obtain, compile and install the Chisel code.
c. Get the appropriate PPD file for your braille device.

For instance, in the case of an Index Basic-D in an Ubuntu environment,
you would do the following:

a. `git clone git://github.com/Igalia/chisel.git`
b. `cd chisel && make && sudo make install`
c. `chisel -S chisel-ppd cat indexbraille/basic-d > basic-d.ppd`

Please see the Chisel `readme.md` for additional options.

# Step 1: Installing your embosser

Having installed the CUPS filters and PPD file, you can now install your
embosser as you would any other CUPS-compatible printer. For instance, to
install your embosser as a local device:

a. Connect your embosser via USB
b. Go to the CUPS administration page: http://localhost:631/
c. Go to Administration and select “Add Printer”
d. Select your embosser and fill in the requested information (name, location, etc)
e. Select the PPD file created in Step 0.

Tip: In the case of a local installation, be sure that the file
`/etc/cups/client.conf` has `"ServerName localhost"` and not
`"ServerName <your.network.here.com>`.

For other configurations, including setting up a networked embosser, you can
find the [full CUPS documentation
here](https://bugzilla.gnome.org/show_bug.cgi?id=690501).

# Step 2: Embossing using Dots

[Dots](https://live.gnome.org/Dots) is a braille translator for GNOME. At
the time of this writing, it is necessary to obtain the [patch that includes
support for the Chisel
format](https://bugzilla.gnome.org/show_bug.cgi?id=690501) allowing you to
specify embosser-specific attributes with which CUPS is unfamiliar.  The
patch is a demonstration which allows you to configure number of copies,
cells per line, and lines per page. It is expected that the Dots developers
will be adding configuration UI for the rest of the Chisel-supported
embosser attributes, including:

* Resolution/dot distance
* Line spacing
* Top margin
* Binding margin

Having obtained Dots with Chisel support, you can easily create and emboss
documents as follows:

a. Launch Dots
b. Go to *File* → *New* to create a new document
c. Write the text you want
d. Go to *Translation* → *Convert* to translate the text
e. Go to *File* → *Print* and select the Index-Braille embosser

<!-- vim: filetype=markdown spell spelllang=en
  -->
