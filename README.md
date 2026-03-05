![spectrum](https://user-images.githubusercontent.com/147840/150885344-903be85d-5790-4bdb-82a2-542845046cc2.jpg)
# spectrum

[ [Docs](https://anentropic.github.io/ocaml-spectrum/) ]

An OCaml library for colour and formatting in the terminal.

It's a little DSL which is exposed via the `Format` module's ["semantic tags"](https://ocaml.org/api/Format.html#tags) feature. String tags are defined for ANSI styles such as bold, underline etc and for named colours from the [xterm 256-color palette][1], as well as 24-bit colours via CSS-style hex codes and RGB or HSL values.

It's inspired by the examples given in ["Format Unraveled"](https://hal.archives-ouvertes.fr/hal-01503081/file/format-unraveled.pdf#page=11), a paper by Richard Bonichon & Pierre Weis, which also explains the cleverness behind OCaml's highly type-safe format string system.

Many features are borrowed from those found in [chalk.js](https://github.com/chalk/chalk)

### Goals

- Simple and ergonomic formatting of strings, especially where multiple styles are applied to same line.
- Focus on colours and text styling
- Support full colour range on modern terminals

### Non-goals

- Any extended "Terminal UI" kind of features, we're just doing text styling (but hopefully it should fit in fine with `Format` or `Fmt`'s existing box and table features etc)
- Maximum performance: if you are formatting high volumes of logs you may like to look at the alternative below. (Performance should be ok but it's not benchmarked and at the end of the day we have to parse the string tags)

### See also

- [`ANSITerminal`](https://github.com/Chris00/ANSITerminal/)
- [`OColor`](https://github.com/marc-chevalier/ocolor)
- [`Fmt`](https://erratique.ch/software/fmt/doc/Fmt/)

These OCaml libs provide support for styling console text with ANSI colours, and some also offer other features useful for formatting and interactivity in the terminal. In contrast, `Spectrum` focuses only on coloured text styling but offers deeper colour support. Hopefully it's complementary to the stdlib and other libs you may be using.

## Installation

```bash
opam install spectrum
```

The main `spectrum` package includes everything you need for terminal color formatting. The implementation is split into several packages:

- `spectrum` - main runtime and user-facing API
- `spectrum_capabilities` - standalone terminal color capability detection
- `spectrum_palette_ppx` - PPX extension for generating palette modules from JSON palette definitions
- `spectrum_palettes` - pre-generated palette modules (Basic and Xterm256)
- `spectrum_tools` - color conversion utilities and query functions

All of these are installed automatically as dependencies when you install `spectrum`.

## Quick start

```ocaml
Spectrum.Simple.printf "@{<green>%s@}\n" "Hello world 👋";;
```

The pattern is `@{<TAG-NAME>CONTENT@}`.

Tag names match the 256 xterm [color names][1] and are case-insensitive. You can also specify colours directly with hex codes, RGB, or HSL values:

```ocaml
Spectrum.Simple.printf "@{<#f0c090>%s@}\n" "Hex color";;
Spectrum.Simple.printf "@{<rgb(240 192 144)>%s@}\n" "RGB color";;
Spectrum.Simple.printf "@{<hsl(60 100 50)>%s@}\n" "HSL color";;
```

Styles like `bold`, `italic`, `underline`, `dim`, `strikethru`, and `overline` are also supported. Tags can be nested and combined with comma-separated compound tags:

```ocaml
Spectrum.Simple.printf "@{<bold,bg:red,yellow>%s@}\n" "Compound tag";;
Spectrum.Simple.printf "@{<green>%s @{<bold>%s@} %s@}\n" "Hello" "world" "there";;
```

For efficient repeated printing, prepare a formatter once:

```ocaml
let reset = Spectrum.prepare_ppf Format.std_formatter in
Format.printf "@{<green>%s@}\n" "Hello world 👋";
reset ();;
```

### Automatic color quantization

Spectrum automatically detects terminal capabilities and quantizes colors accordingly. If you specify an RGB color like `#FF5733` or `rgb(255 87 51)`, Spectrum will:

- On `True_color` terminals: output the exact RGB values using 24-bit ANSI codes
- On `Eight_bit` terminals: quantize to the nearest xterm-256 color using perceptually accurate LAB color space distance
- On `Basic` terminals: quantize to the nearest ANSI-16 color using the same perceptual matching

## Documentation

Documentation is generated with odoc:

```bash
opam install spectrum --with-doc
```

Or online at: [anentropic.github.io/ocaml-spectrum](https://anentropic.github.io/ocaml-spectrum/)

## Changelog

See [CHANGELOG.md](CHANGELOG.md).


[1]: https://www.ditig.com/256-colors-cheat-sheet
