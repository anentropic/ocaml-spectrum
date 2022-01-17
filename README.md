# spectrum
Library for colour and formatting in the terminal.

It's a little DSL which is exposed via OCaml `Format` module's ["semantic tags"](https://ocaml.org/api/Format.html#tags) feature. String tags are defined for ANSI styles such as bold, underline etc and for named colours from the [xterm 256-color palette][1], as well as 24-bit colours via CSS-style hex codes and RGB or HSL values.

It's inspired by the examples given in ["Format Unraveled"](https://hal.archives-ouvertes.fr/hal-01503081/file/format-unraveled.pdf#page=11), a paper by Richard Bonichon & Pierre Weis, which also explains the cleverness behind OCaml's highly type-safe format string system.

### Goals

- Simple and ergonomic formatting of strings, especially where multiple styles are applied to same line.
- Focus on colours and text styling
- Support full colour range on modern terminals

### Non-goals

- Any extended "Terminal UI" kind of features, we're just doing text styling (but hopefully it should fit in fine with `Format` or `Fmt`'s existing box and table features etc)
- Maximum performance: if you are formatting high volumes of logs you may like to look at the alternatoive below. (Performance should be ok but it's not benchmarked and at the end of the day we have to parse the string tags)

### See also

- [`ANSITerminal`](https://github.com/Chris00/ANSITerminal/)
- [`Fmt`](https://erratique.ch/software/fmt/doc/Fmt/)

These two OCaml libs both provide support for styling console text with the basic 16 ANSI colours, and both also offer other features useful for formatting and interactivity in the terminal.

In contrast, `Spectrum` focuses only on coloured text styling but offers deeper colour support. Hopefully it's complementary to the stdlib and other libs you may be using.

## Installation

It's released on opam, so:

```bash
opam install spectrum
```

## Usage

To use Spectrum we have to configure a [pretty-print formatter](https://ocaml.org/api/Format.html#1_Formatters) (type: `Format.formatter`, often just called a `ppf`) in order to enable our custom tag handling.

This looks something like:

```ocaml
let reset_ppf = Spectrum.prepare_ppf Format.std_formatter;; (* prints to stdout *)
Format.printf "@{<green>%s@}\n" "Hello world 👋";;
(* when you're done with Spectrum printing you can use the returned function
   to restore the original ppf state (Spectrum disabled)... *)
reset_ppf ();;
```

The pattern is `@{<TAG-NAME>CONTENT@}`.

So in the example above `<green>` is matching one of the 256 xterm [color names][1]. Tag names are case-insensitive.

Spectrum also provides an "instant gratification" interface, where the prepare/reset of the ppf happens automatically. This looks like:

```ocaml
Spectrum.Simple.printf "@{<green>%s@}\n" "Hello world 👋";;
```

This is handy when doing ad hoc printing, but bear in mind that it is doing the prepare/reset, as well as flushing the output buffer, every time you call one the methods. For most efficient use in your application it's better to use the explicit `prepare_ppf` form.

NOTE: `Format.sprintf` uses its own buffer (not the `Format.str_formatter` shared def) so AFAICT there is no way for `prepare_ppf` to enable Spectrum with it. This means if you need a styled sprintf you have to use `Spectrum.Simple.sprintf`, or use the longer way with `Format.fprintf` and your own buffer described in the [Format docs](https://ocaml.org/api/Format.html#VALsprintf).

### Tags

You can have arbitrarily nested tags, e.g.:

```ocaml
Spectrum.Simple.printf "@{<green>%s @{<bold>%s@} %s@}\n" "Hello" "world" "I'm here";;
```

Which should look like:

![Screenshot 2022-01-15 at 19 08 09](https://user-images.githubusercontent.com/147840/149634761-6c2d1799-4f19-42c3-a3f4-fbeec2b04546.png)

Above, the tag `bold` is used to output one the [ANSI style codes](https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters).

Spectrum defines tags for these styles:

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
Spectrum.Simple.printf "@{<#f0c090>%s@}\n" "Hello world 👋";;
Spectrum.Simple.printf "@{<#f00>%s@}\n" "RED ALERT";;
```

...or CSS-style [rgb(...)](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value/rgb()) or [hsl(...)](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value/hsl()) formats:

```ocaml
Spectrum.Simple.printf "@{<rgb(240 192 144)>%s@}\n" "Hello world 👋";;
Spectrum.Simple.printf "@{<hsl(60 100 50)>%s@}\n" "YELLOW ALERT";;
```
![Screenshot 2022-01-15 at 19 16 50](https://user-images.githubusercontent.com/147840/149634994-609a9f07-74b3-40f6-81c3-9f70914f9400.png)

As in CSS, comma separators between the RGB or HSL components are optional.

NOTE: in CSS you would specify HSL colour as `(<hue degrees> <saturation>% <lightness>%)` but in a format string the `%` has to be escaped as `%%`. Since that is ugly Spectrum will also accept HSL colors without `%` sign (see above). As in CSS, negative Hue angles are supported and angles > 360 will wrap around.

#### Foreground/background

By default you are setting the "foreground" colour, i.e. the text colour.

Any colour tag can be prefixed with a foreground `fg:` or background `bg:` qualifier, e.g.:

```ocaml
Spectrum.Simple.printf "@{<bg:#f00>%s@}\n" "RED ALERT";;
```
![Screenshot 2022-01-15 at 19 24 22](https://user-images.githubusercontent.com/147840/149635190-70af1871-50c8-4e78-9369-a8ce71888106.png)

#### Compound tags

Finally, Spectrum also supports compound tags in comma-separated format, e.g.:

```ocaml
Spectrum.Simple.printf "@{<bg:#f00,bold,yellow>%s@}\n" "RED ALERT";;
```
![Screenshot 2022-01-15 at 19 25 27](https://user-images.githubusercontent.com/147840/149635217-a3b86a4b-e732-4c7e-887d-e907b249214d.png)

### Interface

Spectrum provides two versions of the main module:

1. The default is `Spectrum` and, like stdlib `Format`, invalid tags will simply have no effect on the output string.
2. Alternatively `Spectrum.Exn` will raise an exception if your tags are invalid (i.e. malformed or unrecognised colour name, style name).

Both modules expose the same interface:

```ocaml
val prepare_ppf : Format.formatter -> unit -> unit

module Simple : sig
  (** equivalent to [Format.printf] *)
  val printf : ('a, Format.formatter, unit, unit) format4 -> 'a

  (** equivalent to [Format.eprintf] *)
  val eprintf : ('a, Format.formatter, unit, unit) format4 -> 'a

  (** equivalent to [Format.sprintf] *)
  val sprintf : ('a, Format.formatter, unit, string) format4 -> 'a
end
```

As you can see in the examples in the previous section, `Spectrum.Simple.printf` works just like `Format.printf` from the [OCaml stdlib](https://ocaml.org/api/Format.html#fpp), and `eprintf` and `sprintf` also work just like their `Format` counterparts.

### Capabilities detection

I've ported the logic from the https://github.com/chalk/supports-color/ nodejs lib, which performs some heuristics based on env vars to determine what level of color support is available in the current terminal.

In most cases you can also override the detected level by setting the `FORCE_COLOR` env var.

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
- `Basic`: supports 16 colors, i.e. the 8 basic colors plus "bright" version of each. They are equivalent to the first eight colours of the xterm 256-color set, with bright version accessed by setting the style to **bold**. So the available colour name tags are:
  - ![#000000](https://via.placeholder.com/15/000000/000000?text=+) `black` (with `bold` will display as: `grey`)
  - ![#800000](https://via.placeholder.com/15/800000/000000?text=+) `maroon` (with `bold` will display as: `red`)
  - ![#008000](https://via.placeholder.com/15/008000/000000?text=+) `green` (with `bold` will display as: `lime`)
  - ![#808000](https://via.placeholder.com/15/808000/000000?text=+) `olive` (with `bold` will display as: `yellow`)
  - ![#000080](https://via.placeholder.com/15/000080/000000?text=+) `navy` (with `bold` will display as: `blue`)
  - ![#800080](https://via.placeholder.com/15/800080/000000?text=+) `purple` (with `bold` will display as: `fuchsia`)
  - ![#008080](https://via.placeholder.com/15/008080/000000?text=+) `teal` (with `bold` will display as: `aqua`)
  - ![#c0c0c0](https://via.placeholder.com/15/c0c0c0/000000?text=+) `silver` (with `bold` will display as: `white`)
  - ![#808080](https://via.placeholder.com/15/808080/000000?text=+) `grey`
  - ![#ff0000](https://via.placeholder.com/15/ff0000/000000?text=+) `red`
  - ![#00ff00](https://via.placeholder.com/15/00ff00/000000?text=+) `lime`
  - ![#ffff00](https://via.placeholder.com/15/ffff00/000000?text=+) `yellow`
  - ![#0000ff](https://via.placeholder.com/15/0000ff/000000?text=+) `blue`
  - ![#ff00ff](https://via.placeholder.com/15/ff00ff/000000?text=+) `fuchsia`
  - ![#00ffff](https://via.placeholder.com/15/00ffff/000000?text=+) `aqua`
  - ![#ffffff](https://via.placeholder.com/15/ffffff/000000?text=+) `white`
- `Eight_bit`: supports the [xterm 256-color palette][1]. Named colours beyond the first 16 above should keep their hue when bolded. CSS 24-bit colours likely won't work.
  - NOTE: colour names from that list have been normalised by hyphenating, and where names are repated they are made unique with an alphabetical suffix, e.g. `SpringGreen3` is present in Spectrum as:
    - ![#00af5f](https://via.placeholder.com/15/00af5f/000000?text=+) `spring-green-3a`
    - ![#00d75f](https://via.placeholder.com/15/00d75f/000000?text=+) `spring-green-3b`
  - See the defs at https://github.com/anentropic/ocaml-spectrum/blob/main/lib/lexer.mll#L24
- `True_color`: should support everything

## Changelog

#### 0.6.0
- finally understood what the interface should be 😅
- expose main interface via the parent `Spectrum` module (instead of `Spectrum.Printer` as it used to be)
- main interface is now `Spectrum.prepare_ppf`, allowing Spectrum tag handling with the usual `Format.printf` methods, with the usual buffering behaviour in user's control
- "instant gratification" interface (previously our main interface) is now `Spectrum.Simple.printf` and friends, having the always-flush buffer behaviour
- changed the colour names in `Basic` range to match the list at https://www.ditig.com/256-colors-cheat-sheet
- make `%` char optional in HSL colours, to avoid ugly escaping

#### 0.5.0
- support CSS-style `rgb(...)` and `hsl(...)` color tags

#### 0.4.0
- port the terminal colour capabilities detection from [chalk.js](https://github.com/chalk/chalk)

#### 0.3.0
- expose separate `Exn` and `Noexn` interfaces
- fix for buffer interaction issue (tests broke when updating dep `Fmt.0.9.0`) ...probably affected most uses of `sprintf_into`
- replace `sprintf_into` kludge with a working `sprintf` implementation

#### 0.2.0
- first viable version

## TODOs

- tests for all methods (`sprintf` and the lexer are tested currently), property-based tests
- publish the printer and capabilities-detection as separate opam modules?
- expose variant types for use with explicit `mark_open_stag` and close calls?
- auto coercion to nearest supported colour, for high res colours on unsupported terminals, as per `chalk`
  - don't output any codes if level is `Unsupported`


[1]: https://www.ditig.com/256-colors-cheat-sheet
