We want to codegen the variants and variant-to-rgb functions, using the X11 colors defined here:

- https://www.ditig.com/256-colors-cheat-sheet
- https://www.ditig.com/downloads/256-colors

(NOTE: the latter has many duplicate color names, the json file in this repo has now been edited to disambiguate them)

TODO: we might also consider supporting CSS colour names as secondary aliases - they are almost the same, see:

- https://en.wikipedia.org/wiki/X11_color_names#Clashes_between_web_and_X11_colors_in_the_CSS_color_scheme
- https://www.w3.org/TR/css-color-3/#svg-color

Then we can:

- use the variant as `Format.stag`
- calculated nearest color when downsampling true -> 256 or 256 -> basic

Chalk uses a curious and simple algorithm derived from here: https://github.com/Qix-/color-convert/blob/master/conversions.js#L546 to convert arbitrary RGB color to nearest xterm-256 code.

This seems to do a reasonably sound job, though playing with the numbers I found maybe it gives not always the closest match.

e.g.
```js
ansi256([80, 80, 200]) -> 104  // rgb(135, 135, 215)
ansi256([70, 70, 200]) -> 62   // rgb( 95,  95, 215)
``` 

Both of these are reasonable approximations, but ANSI 62 seems like it'd be a better match for both than 104.

If you check the cheat sheet you can see that ANSI 16-231 have a clear structure, which is I guess what that algo exploits. And 232-255 are a greyscale, also special-cased in that lib.

Alternatively... the most accurate approach should be the one given here https://stackoverflow.com/a/1678481/202168

i.e. convert the colours into LAB space and use that distance function to search the target set for the closest match (this is a https://en.wikipedia.org/wiki/Nearest_neighbor_search I guess)

We could pre-compute the 256 -> basic color mappings. Maybe we don't want to for the True-colour (16.8 million) case though.

We already use [Color](https://github.com/anuragsoni/color) lib, built on [Gg](https://github.com/dbuenzli/gg).

A `Color` is represented as a `Gg.V4` 4-vector and we can obtain the distance between two LAB color vectors via:

```ocaml
(* val distance : Gg.v4 -> Gg.v4 -> float *)
let distance a b = Gg.V4.sub a b |> Gg.V4.norm;;
```

That appears to be the Euclidean distance, see https://en.wikipedia.org/wiki/Color_quantization

https://stackoverflow.com/questions/14618005/how-to-reduce-colors-to-a-specified-palette recommends using a https://en.wikipedia.org/wiki/K-d_tree as a data structure to store the target palette and search nearest matches.

If we revisit spatial indexing in this codebase, use the external `oktree` package rather than keeping indexing research notes here.
