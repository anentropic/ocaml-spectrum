# downsample-nearest-color — Resume Plan

Date: 2026-02-16 (Updated)
Goal: get branch back to a mergeable, test-backed, documented state.

Status refresh (2026-02-16):

**MAJOR MILESTONE COMPLETED:**
- Test reorganization: All tests moved to library-specific `test/` subdirectories
- Comprehensive test coverage: 364 tests passing across all 4 libraries
- Implementation quality improvements: 3 bugs fixed (case-insensitive parsing, safe min/max_fold, proper Result handling)
- All 6 stub test modules now fully implemented with proper coverage

Previous status (2026-02-15):
- `tests/dune` now runs `lexer`, `printing`, `capabilities`, and `conversion`.
- Capability-based serializer selection is wired in `lib/spectrum/spectrum.ml`.
- `tests/capabilities.ml` TODO coverage gaps were filled (recognised CI names + TERM patterns).
- Local validation currently passes with `opam exec -- dune clean && opam exec -- dune test --force`.

## Priority checklist

## P-1 — Rebase conflict fallout (completed)

- [x] Confirmed by git history that hardcoded xterm color-name map in `lexer.mll` had been intentionally removed in favor of parser/palette flow.
- [x] Restored `lib/spectrum/lexer.mll` to the intended post-conflict content from commit `40c1622`.

Definition of done (P-1): lexer no longer carries duplicated hardcoded xterm name map.

---

## P0 — Make branch build/test green again

- [x] Ensure opam switch has required libraries for new split packages (`re`, etc.).
- [x] Run clean build and tests:
  - `opam exec -- dune clean`
  - `opam exec -- dune build`
  - `opam exec -- dune test`
- [x] Capture exact failures (if any) and decide if they are:
  - real regressions,
  - environment/setup issues,
  - expected WIP behavior.

Definition of done (P0): local `dune build` + `dune test` succeed in project switch.

---

## P1 — Re-enable and stabilize core tests (COMPLETED 2026-02-16)

- [x] Re-enable currently commented test targets in `tests/dune` (`lexer`, `printing`).
- [x] Fix any failing tests introduced by parser/library split.
- [x] Add targeted tests for conversion behavior:
  - RGB -> ANSI-256 nearest mapping (including edge greys)
  - RGB -> ANSI-16 nearest mapping
  - serializer behavior under capability-constrained output
- [x] **Test reorganization:** Move all tests to library-specific `test/` subdirectories
- [x] **Comprehensive test implementation:** Fill out all 6 stub test modules
  - Parser: 26 tests (style parsing, colors, tokens, RGBA conversion)
  - Utils: 19 tests (math, color conversions, lists, memoization)
  - Terminal: 15 tests (Basic & Xterm256 palette validation)
  - Loader: 15 tests (JSON parsing, error handling)
  - Palette: 12 tests (LAB conversion, nearest-color algorithms)
  - Query: 17 tests (hex conversion, terminal I/O)
- [x] **Implementation fixes:** Fix 3 bugs found during test implementation
  - Parser: case-insensitive style names
  - Utils: safe min_fold/max_fold (return option)
  - Query: proper Result handling in parse_colour

Definition of done (P1): ✅ **COMPLETE** - 364 tests passing, comprehensive coverage, quality improvements made.

---

## P2 — Finish runtime integration decisions

- [x] Implement capability-based serializer selection in `spectrum.ml`.
- [x] Confirm expected mapping policy by capability:
  - true-color terminal -> keep RGB
  - 256-color terminal -> quantize RGB to nearest ANSI-256
  - basic terminal -> quantize RGB to nearest ANSI-16
- [x] Add serializer-level integration coverage for capability-constrained output.

Definition of done (P2): runtime chooses serializer deterministically and is tested.

---

## P3 — Remove duplicate palette truth and xterm-only assumptions (COMPLETED 2026-02-16)

- [x] **Removed Chalk and ImprovedChalk legacy converters** (~187 lines removed)
  - Eliminated all hardcoded palette logic (RGB values 0,95,135,175,215,255)
  - Eliminated hardcoded color cube and grey-scale conversion algorithms
  - Removed HSV-based ANSI-16 mapping with hardcoded thresholds
- [x] **Adopted palette-derivation approach**
  - Perceptual converter now the sole implementation
  - Uses JSON palette sources (16-colors.json, 256-colors.json) as single source of truth
  - LAB color space with octree-based nearest-neighbor search
- [x] **Custom palette support policy decided**
  - Architecture now supports arbitrary palettes through palette-based nearest search
  - JSON palettes can be customized and PPX will generate appropriate modules

Definition of done (P3): ✅ **COMPLETE** - conversion no longer relies on scattered duplicated constants. Single palette-based converter using JSON sources.

---

## P4 — Optional indexing follow-up

- [ ] If nearest-neighbor indexing is needed later, integrate the external `oktree` package.

Definition of done (P4): indexing strategy is explicit and externalized.

---

## Suggested next session

**✅ ALL WORK COMPLETE - Branch is ready to merge!**

**Completed in this session (2026-02-16):**
1. ✅ Removed Chalk and ImprovedChalk legacy converters (~187 lines)
2. ✅ Updated documentation (README changelog, installation, color quantization sections)
3. ✅ All tests passing (364 tests)

**Ready for merge:**
- Build green in clean switch
- Comprehensive test coverage (364 tests)
- Implementation quality improvements (3 bugs fixed)
- Single source of truth for palette data
- Clean architecture with unified Perceptual converter
- Complete documentation

**Optional future work (post-merge):**
- Evaluate optional indexing follow-up (`P4`) for performance optimization if needed

---

## Handy commands

```bash
# enter project switch (if needed)
opam switch .
eval $(opam env)

# install deps from local opam metadata
opam install . --deps-only --with-test

# clean rebuild + tests
opam exec -- dune clean
opam exec -- dune build
opam exec -- dune test
```

---

## Open questions to resolve early

1. ~~Should nearest-match target strict xterm palette behavior, or support arbitrary palettes as first-class?~~ ✅ **RESOLVED** - Architecture supports arbitrary palettes via JSON sources
2. ~~Is perceptual LAB nearest the desired default, or should compatibility with Chalk be prioritized?~~ ✅ **RESOLVED** - Perceptual LAB is now the sole converter
3. ~~Do you want to keep three converters (Chalk/Improved/Perceptual) publicly exposed, or keep one canonical and move others to internal/bench modules?~~ ✅ **RESOLVED** - Removed Chalk/ImprovedChalk, kept only Perceptual
4. ~~What is acceptable performance target for RGB->palette mapping in hot paths?~~ **DEFERRED** - Can be addressed later with optional indexing (P4) if needed

---

## Merge readiness criteria

- [x] Build green in clean switch
- [x] Full tests re-enabled and passing
- [x] **Comprehensive test coverage implemented (364 tests)**
- [x] **Implementation quality improvements made (3 bugs fixed)**
- [x] Capability-based serializer selection implemented and tested
- [x] **Palette source-of-truth duplication eliminated** (Chalk/ImprovedChalk removed)
- [x] **README updated** to describe new quantization behavior and package split

**Current state:** ✅ **READY TO MERGE** - All work complete! Branch has excellent test coverage, high code quality, single source of truth for palette data, clean architecture, and comprehensive documentation.
