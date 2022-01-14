# spectrum
Library for colour and formatting in the terminal.

It's a little DSL which is exposed via OCaml `Format` module's ["semantic tags"](https://ocaml.org/api/Format.html#tags) feature. String tags are defined for ANSI styles such as bold, underline etc and for named colours from the [xterm 256-color palette](https://www.ditig.com/256-colors-cheat-sheet), as well as 24-bit colours via CSS-style hex codes and RGB or HSL values.

It's inspired by the examples given in ["Format Unraveled"](https://hal.archives-ouvertes.fr/hal-01503081/file/format-unraveled.pdf#page=11), a paper by Richard Bonichon & Pierre Weis, which also explains the cleverness behind OCaml's (mostly) type-safe format string system.

### Goals

- Simple and ergonomic formatting of strings, especially where multiple styles are applied to same line.
- Support full colour range on modern terminals

### Non-goals

- Any extended "Terminal UI" kind of features, we're just doing text styling (but hopefully it should fit in fine with `Format`'s existing box and table features etc)
- Maximum performance: if you are formatting high volumes of logs you may like to look at [alternatives](#alternatives). (Performance should be ok but it's not benchmarked and at the end of the day we have to parse the string tags)

## Installation

It's released on opam, so:

```bash
opam install spectrum
```

## Usage

The basic usage looks like:

```ocaml
Spectrum.Simple.printf "@{<green>%s@}\n" "Hello world 👋";;
```

The pattern is `@{<TAG-NAME>CONTENT@}`. So in the example above `green` is matching one of the 256 xterm [color names](https://www.ditig.com/256-colors-cheat-sheet). Tag names are case-insensitive.

### Tags

You can have arbitrarily nested tags, e.g.:

```ocaml
Spectrum.Simple.printf "@{<green>%s @{<bold>%s@} %s@}\n" "Hello" "world" "I'm here";;
```

Which should look like:  
![Screenshot 2021-09-01 at 12 24 49](https://user-images.githubusercontent.com/147840/131700486-e0551e74-b901-4746-a0e7-f73ca0494a85.png)

If you see what looks like HTML tags instead of styled text then see the note here about [flushing the buffer](#buffering-and-flushing).

Above, the tag `bold` is used to output one the [ANSI style codes](https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters).

Spectrum defines tags for:

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
Spectrum.Simple.printf "@{<hsl(60 100% 50%)>%s@}\n" "YELLOW ALERT";;
```

By default you are setting the "foreground" colour, i.e. the text colour.

Any colour tag can be prefixed with a foreground `fg:` or background `bg:` qualifier, e.g.:

```ocaml
Spectrum.Simple.printf "@{<bg:#f00>%s@}\n" "RED ALERT";;
```
![Screenshot 2021-09-01 at 16 36 55](https://user-images.githubusercontent.com/147840/131701013-db03739c-2b23-4038-95eb-30b11efe751b.png)


Finally, Spectrum also supports compound tags in comma-separated format, e.g.:

```ocaml
Spectrum.Simple.printf "@{<bg:#f00,bold,yellow>%s@}\n" "RED ALERT";;
```
![Screenshot 2022-01-10 at 12 26 28](https://user-images.githubusercontent.com/147840/148767442-5fd2f8a4-9f6b-4a03-86cd-ebea4065b414.png)

### Interface

Spectrum provides two versions of the main module:

1. The default is `Spectrum.Simple` and it will raise an exception if your tags are invalid (i.e. malformed or unrecognised colour name, style name).
2. Alternatively `Spectrum.Simple.Noexn` will swallow any errors, invalid tags will simply have no effect on the output string.

Both modules expose the same interface:

```ocaml
module type Shortcuts = sig
  (** equivalent to [Format.fprintf] *)
  val fprintf :
    Format.formatter -> ('a, Format.formatter, unit, unit) format4 -> 'a

  (** equivalent to [Format.printf] *)
  val printf : ('a, Format.formatter, unit, unit) format4 -> 'a

  (** equivalent to [Format.eprintf] *)
  val eprintf : ('a, Format.formatter, unit, unit) format4 -> 'a

  (** equivalent to [Format.sprintf] *)
  val sprintf : ('a, Format.formatter, unit, string) format4 -> 'a
end

module type Printer = sig
  val prepare_ppf : Format.formatter -> bool -> Format.formatter -> unit

  module Simple : Shortcuts
end
```

As you can see in the examples in the previous section, `Spectrum.Simple.printf` works just like `Format.printf` from the [OCaml stdlib](https://ocaml.org/api/Format.html#fpp), and `fprintf`, `eprintf` and `sprintf` also work just like their `Format` counterparts.

#### Buffering and flushing

One change from `Format` is the optional `?flush:bool` arg to some methods. This is to get around the problem encountered when other formatters are also using the same ppf i.e. `Format.std_formatter`. For example when inside a utop shell, or running tests via Alcotest. In these cases you may find that (with short strings) your `printf` output is entirely buffered, and the formatter is returned to control of utop before it is output, resulting in your styles not being rendered.

In that case you can ensure that Spectrum prints to the screen before relinquishing the formatter with:

```ocaml
Spectrum.Simple.printf ~flush:true "@{<#f00>%s@}\n" "RED ALERT";;
```

Spectrum `sprintf` behaves like `Format.sprintf` i.e. the buffer is always flushed after calling the method. If you need buffering for better performance then [the advice in the Format docs](https://ocaml.org/api/Format.html#VALsprintf) re managing your own buffer via `fprintf` applies to Specturm too.

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
  - `black`
  - `red`
  - `green`
  - `yellow`
  - `blue`
  - `magenta`
  - `cyan`
  - `light-gray` (i.e. white)
- `Eight_bit`: supports the [xterm 256-color palette](https://jonasjacek.github.io/colors/), CSS hex codes likely won't work.
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
- don't flush buffers by default for every method any more
  - `sprintf` will continue to (as per `Format.sprintf`)
  - `fprint`, `printf` and `eprintf` now have a `?(flush=false)` default arg
  - this allows to do buffered printing by default, like `Format` does, but can also call `printf ~flush:true` e.g. when in a utop shell, to ensure styles are rendered

#### 0.5.0
- support CSS-style `rgb(...)` and `hsl(...)` color tags

#### 0.4.0
- port the terminal colour capabilities detection from chalk.js

#### 0.3.0
- expose separate `Exn` and `Noexn` interfaces
- fix for buffer interaction issue (tests broke when updating dep `Fmt.0.9.0`) ...probably affected most uses of `sprintf_into`
- replace `sprintf_into` kludge with a working `sprintf` implementation

#### 0.2.0
- first viable version

## TODOs

- use the actual xterm colour names (seems like the ones I have came from some lib that changed some of them)
  - actually it seems the https://www.ditig.com/256-colors-cheat-sheet source is not ideal as some colour names are repeated with different values (e.g. `IndianRed`)
  - the better source is the `rgb.txt` file from X11 systems, see https://en.wikipedia.org/wiki/X11_color_names  
  https://www.apt-browse.org/browse/ubuntu/trusty/main/all/x11-common/1:7.7+1ubuntu8/file/etc/X11/rgb.txt
- tests for all methods (`sprintf` and the lexer are tested currently)
- add other `Format` methods like `dprintf` etc?
  - can we remove the forced buffer flush for `fprintf` at least?
- publish the printer and capabilities-detection as separate opam modules?
- expose variant types for use with explicit `mark_open_stag` and close calls?
- auto coercion to nearest supported colour, for high res colours on unsupported terminals, as per `chalk`
  - don't output any codes if level is `Unsupported`
