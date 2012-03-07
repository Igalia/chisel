# Chisel document format

## Header and top-level elements

### Header *(recommended)*

    #!chisel

Documents start with the `#!chisel` character sequence. Although when this
is not strictly mandatory, it is needed for certain tools (namely CUPS) to
properly detect the file type.

### `options` *(optional)*

    options {
      -- ...
    }

Defines global options that affect the whole document. The following
options are recognized:


### `document` *(mandatory)*

The top-level element is `document`:

    document {
      -- ...
    }

Those elements contain an arbitrary number of [content
elements](#Content_elements).


## Content elements

### `text`

    text "Small portion of text"
    text {
      "Bigger chunk of text composed out of"
      "several strings which will be "
      "concatenated."
    }
    text [[Long text
    with embedded
    newlines]]

Text elements contain strings to be embossed.

<!-- vim: filetype=markdown spell spelllang=en
  -->
