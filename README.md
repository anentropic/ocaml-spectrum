# spectrum
Library for colour and formatting in the terminal.

Using OCaml Format module's ["semantic tags"](https://ocaml.org/api/Format.html#tags) feature, with tags defined for named colours from the [xterm 256-color palette](https://jonasjacek.github.io/colors/), as well as 24-bit colours via CSS-style hex codes.

## Usage

The basic usage looks like:

```ocaml
Spectrum.Printer.printf "@{<green>%s@}\n" "Hello world 👋";;
```

The pattern is `@{<TAG-NAME>CONTENT@}`. So in the example above `green` is matching one of the 256 xterm [color names](https://jonasjacek.github.io/colors/).

### Tags

We can have arbitrarily nested tags, e.g.:

```ocaml
Spectrum.Printer.printf "@{<green>%s @{<bold>%s@} %s@}\n" "Hello" "world" "I'm here";;
```

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

As well as the named palette colours you can directly specify an arbitrary colour using CSS-style hex codes:

```ocaml
Spectrum.Printer.printf "@{<#f0c090>%s@}\n" "Hello world 👋";;
Spectrum.Printer.printf "@{<#f00>%s@}\n" "RED ALERT";;
```

By default we are setting the "foreground" colour, i.e. the text colour. But any colour tag can be prefixed with a foreground/background qualifier:

```ocaml
Spectrum.Printer.printf "@{<bg:#f00>%s@}\n" "RED ALERT";;
```

Finally, Spectrum also supports compound tags in `colour:style` format, e.g.:

```ocaml
Spectrum.Printer.printf "@{<#f00:bold>%s@}\n" "RED ALERT";;
```

### Methods

As you can see in the examples above, `Spectrum.Printer.printf` works just like `Format.printf` in the [OCaml stdlib](https://ocaml.org/api/Format.html#fpp).

We also expose equivalents of `fprintf` and `eprintf`.

Under the hood all of these work via partial application, which is how Spectrum is able to support formats with arbitrary numbers of args.

However this causes a problem when we want an equivalent to `sprintf` since that has to return a value.

So far I couldn't think of a clever workaround so Spectrum provides this kludge instead:

```ocaml
let result = ref "" in
Spectrum.Printer.sprintf_into result "@{<green>%s@}\n" "Hello world 👋";
Format.print_string !result;
```

The `sprintf_into` method takes a `string ref` as its first arg and will update that with the result value.
