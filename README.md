# spectrum
Library for colour and formatting in the terminal.

Using OCaml Format module's ["semantic tags"](https://ocaml.org/api/Format.html#tags) feature, with tags defined for named colours from the [xterm 256-color palette](https://jonasjacek.github.io/colors/), as well as 24-bit colours via CSS-style hex codes.

It's inspired by the examples given in [Format Unraveled](https://hal.archives-ouvertes.fr/hal-01503081/file/format-unraveled.pdf#page=11), a paper by Richard Bonichon & Pierre Weis, which also explains the cleverness behind OCaml's (mostly) type-safe format string system.

## Installation

It's released on opam, so:

```bash
opam install spectrum
```

## Usage

The basic usage looks like:

```ocaml
Spectrum.Printer.printf "@{<green>%s@}\n" "Hello world 👋";;
```

The pattern is `@{<TAG-NAME>CONTENT@}`. So in the example above `green` is matching one of the 256 xterm [color names](https://jonasjacek.github.io/colors/). Tag names are case-insensitive.

### Tags

You can have arbitrarily nested tags, e.g.:

```ocaml
Spectrum.Printer.printf "@{<green>%s @{<bold>%s@} %s@}\n" "Hello" "world" "I'm here";;
```

Which should look like:  
![Screenshot 2021-09-01 at 12 24 49](https://user-images.githubusercontent.com/147840/131700486-e0551e74-b901-4746-a0e7-f73ca0494a85.png)

Here the tag `bold` is used to output one the [ANSI style codes](https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters). Spectrum defines tags for:

- `bold`
- `dim`
- `italic`
- `underline`
- `blink`
- `rapid-blink`
- `inverse`
- `hidden`
- `strikethru`

As well as the named palette colours you can directly specify an arbitrary colour using short or long CSS-style hex codes:

```ocaml
Spectrum.Printer.printf "@{<#f0c090>%s@}\n" "Hello world 👋";;
Spectrum.Printer.printf "@{<#f00>%s@}\n" "RED ALERT";;
```

By default you are setting the "foreground" colour, i.e. the text colour. But any colour tag can be prefixed with a foreground `fg:` or background `bg:` qualifier, e.g.:

```ocaml
Spectrum.Printer.printf "@{<bg:#f00>%s@}\n" "RED ALERT";;
```
![Screenshot 2021-09-01 at 16 36 55](https://user-images.githubusercontent.com/147840/131701013-db03739c-2b23-4038-95eb-30b11efe751b.png)


Finally, Spectrum also supports compound tags in comma-separated format, e.g.:

```ocaml
Spectrum.Printer.printf "@{<bg:#f00,bold,yellow>%s@}\n" "RED ALERT";;
```

### Interface

Spectrum provides two versions of the main module:

1. The default is `Spectrum.Printer` and it will raise an exception if your tags are invalid (i.e. malformed or unrecognised colour name, style name).
2. Alternatively `Spectrum.Printer.Noexn` will swallow any errors, invalid tags will simply have no effect on the output string.

Both modules expose the same interface:

```ocaml
(** equivalent to [Format.fprintf] *)
val fprintf :
  Format.formatter -> ('a, Format.formatter, unit, unit) format4 -> 'a

(** equivalent to [Format.printf] *)
val printf : ('a, Format.formatter, unit, unit) format4 -> 'a

(** equivalent to [Format.eprintf] *)
val eprintf : ('a, Format.formatter, unit, unit) format4 -> 'a

(** equivalent to [Format.sprintf] *)
val sprintf : ('a, Format.formatter, unit, string) format4 -> 'a
```

As you can see in the examples in the previous section, `Spectrum.Printer.printf` works just like `Format.printf` from the [OCaml stdlib](https://ocaml.org/api/Format.html#fpp), and `fprintf`, `eprintf` and `sprintf` also work just like their `Format` counterparts.

### Capabilities detection

I've ported the logic from the https://github.com/chalk/supports-color/ nodejs lib, which performs some heuristics based on env vars to determine what level of color support is available.

In most cases you can also override the detected by setting the `FORCE_COLOR` env var.

The following method is provided:

```ocaml
Spectrum.Capabilities.supported_color_levels () -> color_level_info

type color_level_info = {
  stdout : color_level;
  stderr : color_level;
}
```

The following levels are recognised:

```ocaml
type color_level =
  | Unsupported (* FORCE_COLOR=0 or FORCE_COLOR=false *)
  | Basic       (* FORCE_COLOR=1 or FORCE_COLOR=true *)
  | Eight_bit   (* FORCE_COLOR=2 *)
  | True_color  (* FORCE_COLOR=3 *)
```

- `Unsupported`: probably best not to use colors or styling
- `Basic`: 16 colors, i.e. the 8 basic colors plus "bright" version of each. They are equivalent to the first eight colours of the xterm 256-color set, with bright version accessed by setting the style to **bold**. So the available colour name tags are:
  - `black`
  - `red`
  - `green`
  - `yellow`
  - `blue`
  - `magenta`
  - `cyan`
  - `light-gray` (i.e. white)
- `Eight_bit`: the [xterm 256-color palette](https://jonasjacek.github.io/colors/), CSS hex codes likely won't work.
- `True_color`: should support everything

## Alternatives

AFAICT the main lib for this in the OCaml world is [`ANSITerminal`](https://github.com/Chris00/ANSITerminal/). It supports more than just colour and styles, providing tools for other things you might need in a terminal app like interacting with the cursor. It doesn't use "semantic tags", but provides analogs of the `*printf` functions which now take a list of styles as the first arg, with that styling applied to the formatted string as a whole. For named colours it supports only the [basic set of eight](https://en.wikipedia.org/wiki/ANSI_escape_code#3-bit_and_4-bit) i.e. those which should be supported by any terminal.

There is also [`Fmt`](https://erratique.ch/software/fmt/doc/Fmt/). Unfortunately I couldn't work out how to use it from reading the docs, which don't give any examples. I think it may also integrate with `Cmdliner` somehow, which could be handy. It appears to support the eight basic colours and styles and exposes a `val styled : style -> 'a t -> 'a t` signature (where `'a t` is _"the type for formatters of values of type `'a.`"_), which looks similar to ANSITerminal but only applying a single style at a time i.e. no bold+red. (I guess you can do that by nesting function calls though).

In other languages there are libs like [colored](https://gitlab.com/dslackw/colored) (Python) and [chalk](https://www.npmjs.com/package/chalk) (JS) ...the latter being one of the most comprehensive I've seen.

### Update:

I worked out how to use `Fmt`, which is like this:

```ocaml
Fmt.set_style_renderer Fmt.stdout Fmt.(`Ansi_tty);;
Fmt.styled Fmt.(`Fg `Red) Fmt.string Fmt.stdout "wtf\n";;
Fmt.styled Fmt.(`Bg `Blue) Fmt.int Fmt.stdout 999;;
```

## TODOs

- tests for all methods (`sprintf` and the lexer are tested currently)
- auto coercion to nearest supported colour, for high res colours on unsupported terminals, as per `chalk`
  - don't output any codes if level is `Unsupported`
