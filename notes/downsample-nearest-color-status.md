# downsample-nearest-color — Branch Status

Date: 2026-02-14
Compared against: `main`
Current branch: `downsample-nearest-color`

Post-fix update (2026-02-14): `lib/spectrum/lexer.mll` has now been restored to the intended parser-delegating version from commit `40c1622` (the large hardcoded color-name map was removed again after rebase conflict fallout).

## Executive summary

This branch is a substantial WIP toward color downsampling / nearest-match conversion and palette modularization.

High-level delta vs `main`:

- Commits ahead of `main`: 14
- Files changed: 33
- Net diff: `+7168 / -147`

Key outcomes so far:

1. Repo architecture split into 3 public libraries:
   - `spectrum` (runtime tagging/printing/parser integration)
   - `spectrum_palette` (palette loading + PPX codegen from JSON)
   - `spectrum_tools` (conversion algorithms, query tools)
2. Parser palette definitions moved from hardcoded forms to generated modules via PPX over JSON palette files.
3. `lexer.mll` now correctly delegates parsing/validation to `Parser` instead of carrying a giant hardcoded xterm name map.
4. Multiple RGB->restricted palette conversion strategies implemented, including perceptual (LAB-distance) nearest matching.
5. Serializer path in `spectrum` now uses quantization for lower capability modes.

---

## What changed (by area)

### 1) Project structure and packaging

- Old top-level library layout replaced with sub-libraries under `lib/`:
  - `lib/spectrum/`
  - `lib/spectrum_palette/`
  - `lib/spectrum_tools/`
- New opam package files added:
  - `spectrum_palette.opam`
  - `spectrum_tools.opam`
- `dune-project` now defines multiple packages (with TODO placeholders in metadata for new packages).

### 2) Palette model/codegen

- Added JSON palette sources:
  - `lib/spectrum_palette/16-colors.json`
  - `lib/spectrum_palette/256-colors.json`
- Added PPX rewriter machinery to generate `Palette.M` modules from JSON config:
  - `lib/spectrum_palette/spectrum_palette.ml`
- Parser now consumes generated modules:
  - `module Basic : Palette.M = [%palette "lib/spectrum_palette/16-colors.json"]`
  - `module Xterm256 : Palette.M = [%palette "lib/spectrum_palette/256-colors.json"]`

### 3) Conversion/downsampling logic

- Added conversion module with three strategies:
  - `Chalk` (close port of Chalk.js style mapping)
  - `Improved` (better bucket boundaries and grey detection)
  - `Perceptual` (candidate set + LAB distance nearest)
- Core implementation in:
  - `lib/spectrum_tools/convert.ml`
- The perceptual path currently drives runtime quantization in serializers.

### 4) Runtime integration in spectrum

- `lib/spectrum/spectrum.ml` adds serializer modules:
  - `True_color_Serializer`
  - `Xterm256_Serializer` (RGB quantized to ANSI-256)
  - `Basic_Serializer` (RGB/256 quantized to ANSI-16)
- Current default exported module still wires true-color serializer for `Exn` and `Noexn`.
- Explicit TODO remains for capability-based serializer selection.

### 6) Terminal color query utilities

- Added xterm fg/bg query helper and parsing:
  - `lib/spectrum_tools/query.ml`
- Added scripts for experimentation:
  - `bin/query.py`
  - `bin/query.sh`
- Demo CLI updated to exercise `spectrum` and query functionality.

### 7) Tests and tooling state

- Test target in `tests/dune` currently narrowed to capabilities only:
  - `lexer` and `printing` tests commented out.
- Additional TODO comments inserted in `tests/capabilities.ml` for broader coverage.
- VSCode setting change includes `editor.formatOnType`.

---

## Current branch health snapshot

In the current local switch/environment, build and tests do not pass due to missing dependencies:

- Missing library `re`

Observed via:

- `opam exec -- dune build`
- `opam exec -- dune test`

So this branch should be treated as **functional WIP**, not yet fully green.

---

## Notes on implementation direction

The branch’s chosen approach is coherent:

1. **Data-driven palettes** (JSON + PPX) to avoid hand-maintained giant match statements.
2. **Runtime quantization for arbitrary RGB** with a perceptual nearest-match strategy.

This matches your remembered goal: utilities for normalizing arbitrary colors into restricted palettes, with groundwork for broader/custom palette support.

---

## Main open risks / known rough edges

1. Build reproducibility in current switch (deps missing locally).
2. Duplicate/parallel sources of palette truth (not fully centralized yet).
3. Custom palette support still partly xterm-assumption-based in conversion code.
4. Test suite reduced while feature work progressed.
5. Capability-driven serializer selection still TODO in runtime wiring.

---

## Suggested reading order to re-orient quickly

1. `lib/spectrum/spectrum.ml` (integration + serializer selection TODO)
2. `lib/spectrum/parser.ml` (generated palette usage)
3. `lib/spectrum/lexer.mll` (now parser-delegating after fix)
4. `lib/spectrum_tools/convert.ml` (actual quantization logic)
5. `lib/spectrum_palette/spectrum_palette.ml` (PPX generation model)
7. `tests/dune` and `tests/capabilities.ml` (test status)
