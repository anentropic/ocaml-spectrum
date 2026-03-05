## Changelog

#### 1.0.0.alpha
Major enhancements!
- **automatic color quantization**: RGB and HSL colors are now automatically downsampled to ANSI-256 or ANSI-16 based on detected terminal capabilities
- **perceptual color matching**: use LAB color space with octree-based nearest-neighbor search for accurate color quantization
- **unified converter architecture**: removed legacy `Chalk` and `ImprovedChalk` converters in favor of the `Perceptual` converter
- **custom palette support**: architecture now supports arbitrary palettes via JSON sources
- **package split**: `spectrum` (main runtime), `spectrum_palette` (palette definitions), `spectrum_palette_ppx` (palette codegen PPX), `spectrum_tools` (color conversion utilities), and `spectrum_palettes` (generated palette modules)
- palette JSON definitions live in `lib/spectrum_palette/*.json`, with PPX-generated modules in `lib/spectrum_palettes/terminal.ml`
- **`Spectrum.Stag` module**: type-safe variant-based API for `Format.stag`, allowing pre-validated tag construction with zero parsing overhead as an alternative to string tags
- **`spectrum_capabilities` package**: terminal capability detection extracted into a standalone opam package (zero dependency on the rest of Spectrum)
- **property-based tests**: QCheck2 property tests for parser, lexer, color conversions, capabilities detection, and stag/string-tag equivalence
- **comprehensive test coverage**: all modules now tested
- **odoc documentation**: comprehensive API docs with examples

#### 0.7.0
- minimum OCaml version raised to 4.14
- replace `pcre` dependency with `re` (pure OCaml)

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
