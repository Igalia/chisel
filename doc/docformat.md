# Chisel document format

## Header and top-level elements

### Header *(recommended)*

    #!chisel

Documents start with the `#!chisel` character sequence. Although when this
is not strictly mandatory, it is needed for certain tools (namely CUPS) to
properly detect the file type.

### `options` *(optional)*

    options {
      dot_distance = 2.5;
      line_spacing = "normal";
      -- ...
    }

Defines global options that affect the whole document. The following
options are recognized:

* `dot_distance`: Distance between dots, in millimeters.

* `line_spacing`: Spacing between text lines. Possible values are `"normal"`
(or `"single"`, which has the same meaning), `"double"` or a numeric value,
interpreted as the space between lines in millimeters.

None of the options is mandatory. If not specified, the values used for
those options are those considered as reasonable defaults for the output
device in use.


### `document` *(mandatory)*

The top-level element is `document`:

    document {
      -- ...
    }

Those elements contain an arbitrary number of [content
elements](#Content_elements).


## Content elements

### `text`

Document tree element: `doctree.text`

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

### `raw`

Document tree element: `doctree.raw`

    raw ("device-model", "raw data")

Blob of raw data that is to be sent to the device as-is. The data will be
sent only when the document is being sent to a particular *device-model*,
and ignored for the rest of devices. **Using `raw()` is discouraged** as
it violates the purpose of the document being device-independent, still
it is provided as a way to do fine-grained control for particular devices.

<!-- vim: filetype=markdown spell spelllang=en
  -->
