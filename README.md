# spectrum
Library for colour and formatting in the terminal.

It's a little DSL which is exposed via OCaml `Format` module's ["semantic tags"](https://ocaml.org/api/Format.html#tags) feature. String tags are defined for ANSI styles such as bold, underline etc and for named colours from the [xterm 256-color palette][1], as well as 24-bit colours via CSS-style hex codes and RGB or HSL values.

It's inspired by the examples given in ["Format Unraveled"](https://hal.archives-ouvertes.fr/hal-01503081/file/format-unraveled.pdf#page=11), a paper by Richard Bonichon & Pierre Weis, which also explains the cleverness behind OCaml's highly type-safe format string system.

### Goals

- Simple and ergonomic formatting of strings, especially where multiple styles are applied to same line.
- Support full colour range on modern terminals

### Non-goals

- Any extended "Terminal UI" kind of features, we're just doing text styling (but hopefully it should fit in fine with `Format` or `Fmt`'s existing box and table features etc)
- Maximum performance: if you are formatting high volumes of logs you may like to look at [alternatives](#alternatives). (Performance should be ok but it's not benchmarked and at the end of the day we have to parse the string tags)

## Installation

It's released on opam, so:

```bash
opam install spectrum
```

## Usage

To use Spectrum we have to configure a [pretty-print formatter](https://ocaml.org/api/Format.html#1_Formatters) (type: `Format.formatter`, often just called a `ppf`) in order to enable our custom tag handling.

This looks something like:

```ocaml
let reset_ppf = Spectrum.prepare_ppf Format.std_formatter;;
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


Finally, Spectrum also supports compound tags in comma-separated format, e.g.:

```ocaml
Spectrum.Simple.printf "@{<bg:#f00,bold,yellow>%s@}\n" "RED ALERT";;
```
![Screenshot 2022-01-15 at 19 25 27](https://user-images.githubusercontent.com/147840/149635217-a3b86a4b-e732-4c7e-887d-e907b249214d.png)

### Interface

Spectrum provides two versions of the main module:

1. The default is `Spectrum` and, like stdlib `Format`, it will swallow any errors so that invalid tags will simply have no effect on the output string.
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
  - <span style="color:#000000">■</span> `black` (with `bold` will display as: `grey`)
  - <span style="color:#800000">■</span> `maroon` (with `bold` will display as: `red`)
  - <span style="color:#008000">■</span> `green` (with `bold` will display as: `lime`)
  - <span style="color:#808000">■</span> `olive` (with `bold` will display as: `yellow`)
  - <span style="color:#000080">■</span> `navy` (with `bold` will display as: `blue`)
  - <span style="color:#800080">■</span> `purple` (with `bold` will display as: `fuchsia`)
  - <span style="color:#008080">■</span> `teal` (with `bold` will display as: `aqua`)
  - <span style="color:#c0c0c0">■</span> `silver` (with `bold` will display as: `white`)
  - <span style="color:#808080">■</span> `grey`
  - <span style="color:#ff0000">■</span> `red`
  - <span style="color:#00ff00">■</span> `lime`
  - <span style="color:#ffff00">■</span> `yellow`
  - <span style="color:#0000ff">■</span> `blue`
  - <span style="color:#ff00ff">■</span> `fuchsia`
  - <span style="color:#00ffff">■</span> `aqua`
  - <span style="color:#ffffff">■</span> `white`
- `Eight_bit`: supports the [xterm 256-color palette][1]. Named colours beyond the first 16 above should keep their hue when bolded. CSS 24-bit colours likely won't work.
  - NOTE: colour names from that list have been normalised by hyphenating, and where names are repated they are made unique with an alphabetical suffix, e.g. `SpringGreen3` is present in Spectrum as:
    - <span style="color:#00af5f">■</span> `spring-green-3a`
    - <span style="color:#00d75f">■</span> `spring-green-3b`
  - See the defs at https://github.com/anentropic/ocaml-spectrum/blob/main/lib/lexer.mll#L24
- `True_color`: should support everything

## Alternatives

AFAICT the main lib for this in the OCaml world is [`ANSITerminal`](https://github.com/Chris00/ANSITerminal/). It supports more than just colour and styles, providing tools for other things you might need in a terminal app like interacting with the cursor. It doesn't use "semantic tags", but provides analogs of the `*printf` functions which now take a list of styles as the first arg, with that styling applied to the formatted string as a whole. For named colours it supports only the [Basic set](https://en.wikipedia.org/wiki/ANSI_escape_code#3-bit_and_4-bit) i.e. those which should be supported by any terminal.

There is also [`Fmt`](https://erratique.ch/software/fmt/doc/Fmt/). Unfortunately I couldn't work out how to use it from reading the docs, which don't give any examples. I think it may also integrate with `Cmdliner` somehow, which could be handy. It appears to support the Basic colours and styles and exposes a `val styled : style -> 'a t -> 'a t` signature (where `'a t` is _"the type for formatters of values of type `'a.`"_ 🤷‍♂️ ), which looks similar to ANSITerminal but only applying a single style at a time i.e. no bold+red. (I guess you can do that by nesting function calls though).

In other languages there are libs like [colored](https://gitlab.com/dslackw/colored) (Python) and [chalk](https://www.npmjs.com/package/chalk) (JS) ...the latter being one of the most comprehensive I've seen.

#### Update:

I worked out how to use `Fmt`, which is like this:

```ocaml
Fmt.set_style_renderer Fmt.stdout Fmt.(`Ansi_tty);;
Fmt.styled Fmt.(`Fg `Red) Fmt.string Fmt.stdout "wtf\n";;
Fmt.styled Fmt.(`Bg `Blue) Fmt.int Fmt.stdout 999;;
```

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

- tests for all methods (`sprintf` and the lexer are tested currently)
- publish the printer and capabilities-detection as separate opam modules?
- expose variant types for use with explicit `mark_open_stag` and close calls?
- auto coercion to nearest supported colour, for high res colours on unsupported terminals, as per `chalk`
  - don't output any codes if level is `Unsupported`


[1]: https://www.ditig.com/256-colors-cheat-sheet
