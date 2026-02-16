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

## P3 — Remove duplicate palette truth and xterm-only assumptions

- [ ] Consolidate ANSI-16 definitions so one source of truth drives:
  - parser palette,
  - conversion candidate sets,
  - code mappings.
- [ ] Replace hardcoded conversion assumptions where possible with palette-derived data.
- [ ] Decide explicit support policy for custom palettes:
  - strict xterm-compatible only, or
  - arbitrary palettes with runtime nearest search.

Definition of done (P3): conversion no longer relies on scattered duplicated constants.

---

## P4 — Optional indexing follow-up

- [ ] If nearest-neighbor indexing is needed later, integrate the external `oktree` package.

Definition of done (P4): indexing strategy is explicit and externalized.

---

## Suggested next session

**With P0, P1, P2 now complete, focus shifts to polish and merge readiness:**

1. Start de-duplication work (`P3`) to reduce duplicate palette truth.
2. Decide explicit custom-palette support policy (`P3`).
3. Update docs/release notes for quantization + package split (merge readiness).
4. Consider merging to main - test coverage is now comprehensive and implementation quality is high.

If time remains:

5. Evaluate optional indexing follow-up (`P4`) before any optimisation work.

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

1. Should nearest-match target strict xterm palette behavior, or support arbitrary palettes as first-class?
2. Is perceptual LAB nearest the desired default, or should compatibility with Chalk be prioritized?
3. Do you want to keep three converters (Chalk/Improved/Perceptual) publicly exposed, or keep one canonical and move others to internal/bench modules?
4. What is acceptable performance target for RGB->palette mapping in hot paths?

---

## Merge readiness criteria

- [x] Build green in clean switch
- [x] Full tests re-enabled and passing
- [x] **Comprehensive test coverage implemented (364 tests)**
- [x] **Implementation quality improvements made (3 bugs fixed)**
- [x] Capability-based serializer selection implemented and tested
- [ ] Palette source-of-truth duplication reduced
- [ ] README/CHANGES updated to describe new quantization behavior and package split

**Current state:** Branch is in excellent shape with comprehensive test coverage and high code quality. Main blockers for merge are documentation/polish items rather than technical issues.
