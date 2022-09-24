We want to codegen the variants and variant-to-rgb functions, using the X11 colors defined here:

- https://www.ditig.com/256-colors-cheat-sheet
- https://www.ditig.com/downloads/256-colors

(NOTE: the latter has many duplicate color names, the json file in this repo has now been edited to disambiguate them)

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

https://stackoverflow.com/questions/14618005/how-to-reduce-colors-to-a-specified-palette recommends using a https://en.wikipedia.org/wiki/K-d_tree I guess as a data structure to store the target palette and then search it for nearest match.

https://www.cs.umd.edu/~mount/Papers/DCC.pdf compares perforamnce of the K-d tree search with two related approaches.

https://observablehq.com/@tmcw/octree-color-quantization

https://cstheory.stackexchange.com/questions/8470/why-would-one-ever-use-an-octree-over-a-kd-tree ...seems octree is simpler and suitable when the distribution is fairly homogenous - which the 256 color palette basically is.

I think how nearest neighbour on octree would work for this is:

- index all the xterm colours into the octree... the tree recursively divides the 3D colour space up into regular cubes, the colour index tells us which cube a colour is found in (?)
- for an arbitrary colour, this allows us to rapidly find the xterm colours in the same cube
- according to https://link.springer.com/article/10.1007/s00138-017-0889-4 the usual algorithm then backtracks to add points from adjacent cubes (since the cubes are buckets and actual NN may be in the adjacent one)
  - the paper actually provides a fast non-backtracking algo by pre-computing voronoi cells of the palette
  - octree is used to quickly find the voronoi cell that the src colour falls into... each leaf cube of the octree should be a sub-region of one voronoi cell (i.e. the octree is subdivided until no leaves intersect multiple cells)
  - centre point of the leaf voronoi cell is the nearest neighbour i.e. xterm palette colour
- I guess if no candidates are found it backtracks further until some are found
- we now have a shortlist of nearest neighbour candidates, we can compare distance of each against our src colour
