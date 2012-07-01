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

* `copies`: Number of copies to be rendered once the document is sent to
a device. This must be an integer.

* `dot_distance`: Distance between dots, in millimeters.

* `line_spacing`: Spacing between text lines. Possible values are `"normal"`
(or `"single"`, which has the same meaning), `"double"` or a numeric value,
interpreted as the space between lines in millimeters.

* `characters_per_line`: Number of characters to be fitted in each line.

* `lines_per_page`: Number of lines that are to be fitted in each page.

* `binding_margin`: Amount of margin to leave on the left side of pages,
most of the time for binding purposes. This is given as the number of
character cells left empty at the beginning of the line.

* `top_margin`: Number of lines to leave empty at the top of each page.

None of the options is mandatory. If not specified, the values used for
those options are those considered as reasonable defaults for the output
device in use.


### `document` *(mandatory)*

The top-level element is `document`:

    document {
      -- ...
    }

Those elements contain an arbitrary number of [content
elements](#Content_elements) and [grouping elements](#Grouping_elements).


## Grouping elements

### `part`

Document tree element: `doctree.part`

    part {
      dot_distance = 2.5;
      -- more options...
    } {
      text "Foo";
      -- more content or grouping elements...
    }

Parts may contain both other grouping elements and [content
elements](#Content_elements). Parts have two arguments:

* A set of options to be applied to the contents of the part. Valid options
are the same as for the `options` top-level element. The options given will
override the global document options  for the content *inside* the part.
Note that some output devices may not be able to set certain options for
a document part, actual outcome depends on the capabilities of the hardware.

* The contents of the part.


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

    raw ("output-name", "raw data")

Blob of raw data that is to be sent to the device as-is. The data will be
sent only when the document is being sent to a particular *output*,
and ignored for the rest of devices. **Using `raw()` is discouraged** as
it violates the purpose of the document being device-independent, still
it is provided as a way to do fine-grained control for particular devices.

The *output* name may be:

* A particular device identifier containing the manufacturer and model
name, e.g. `indexbraille/basic-d`. Output will be done only to devices
of that particular model.

* A wildcard for a specific manufacturer, using `*` as the model name, e.g.
`indexbraille/*`. Output will be sent to any device of the specified
manufacturer.

* The name of the output renderer being used, e.g. `indexbraille-v4`. Output
will be sent to any device using that renderer, regardless of the particular
manufacturer and model.

<!-- vim: filetype=markdown spell spelllang=en
  -->
