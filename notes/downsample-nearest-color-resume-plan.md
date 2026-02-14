# downsample-nearest-color — Resume Plan

Date: 2026-02-14
Goal: get branch back to a mergeable, test-backed, documented state.

## Priority checklist

## P-1 — Rebase conflict fallout (completed)

- [x] Confirmed by git history that hardcoded xterm color-name map in `lexer.mll` had been intentionally removed in favor of parser/palette flow.
- [x] Restored `lib/spectrum/lexer.mll` to the intended post-conflict content from commit `40c1622`.

Definition of done (P-1): lexer no longer carries duplicated hardcoded xterm name map.

---

## P0 — Make branch build/test green again

- [ ] Ensure opam switch has required libraries for new split packages (`pcre`, `psq`, etc.).
- [ ] Run clean build and tests:
  - `opam exec -- dune clean`
  - `opam exec -- dune build`
  - `opam exec -- dune test`
- [ ] Capture exact failures (if any) and decide if they are:
  - real regressions,
  - environment/setup issues,
  - expected WIP behavior.

Definition of done (P0): local `dune build` + `dune test` succeed in project switch.

---

## P1 — Re-enable and stabilize core tests

- [ ] Re-enable currently commented test targets in `tests/dune` (`lexer`, `printing`).
- [ ] Fix any failing tests introduced by parser/library split.
- [ ] Add targeted tests for conversion behavior:
  - RGB -> ANSI-256 nearest mapping (including edge greys)
  - RGB -> ANSI-16 nearest mapping
  - behavior around thresholds / candidate ties

Definition of done (P1): full test list active and passing.

---

## P2 — Finish runtime integration decisions

- [ ] Implement capability-based serializer selection (currently TODO in `spectrum.ml`).
- [ ] Confirm expected mapping policy by capability:
  - true-color terminal -> keep RGB
  - 256-color terminal -> quantize RGB to nearest ANSI-256
  - basic terminal -> quantize to nearest ANSI-16
- [ ] Add integration tests for end-to-end tag rendering under each capability mode.

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

## P4 — Decide octree fate (productize or park)

- [ ] Choose one:
  1. integrate octree search as production nearest-neighbor backend,
  2. keep perceptual candidate strategy as production and move octree to experimental docs,
  3. gate octree behind feature flag/module boundary.
- [ ] If integrating octree, add correctness tests against brute-force nearest for sample sets.

Definition of done (P4): one clear nearest-neighbor strategy is canonical.

---

## Suggested first session (fast restart)

1. Build/test baseline and fix environment (`P0`).
2. Re-enable tests (`P1`) to recover confidence.
3. Implement capability-based serializer dispatch (`P2`) so feature is user-visible.

If time remains:

4. Start de-duplication work (`P3`) before touching octree decisions.

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

- [ ] Build green in clean switch
- [ ] Full tests re-enabled and passing
- [ ] Capability-based serializer selection implemented and tested
- [ ] Palette source-of-truth duplication reduced
- [ ] README/CHANGES updated to describe new quantization behavior and package split
