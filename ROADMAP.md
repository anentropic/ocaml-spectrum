# Roadmap

- add "style as value" support - a nice way to reuse styles
- that likely wants some kind of 'builder' interface similar to <https://github.com/leostera/minttea/tree/main/spices>
- some way to register and use palettes via env vars?

### Quantization palettes vs Named-colour palettes

So far I have sort of conflated these but there are two distinct concerns.

For quantization there is not much use for custom palettes, there is no way to infer (especially at compile time) what palette the given terminal is running so typically the basic 16 or xterm 256 will always be used.

Secondarily there is value in defining 'palettes' of named colours. These may have any number of colours in them. These colours can be quantised to the 16 & 256 colour 'quanitzation palettes' at compile time.

We possibly want some functor that takes 16 & 256 colour quantization palettes plus an optional styling palette (default would be one that combines basic-16 + xterm-256). The spectrum methods would come from that functor, with the styling palette providing the set of recognised names.
