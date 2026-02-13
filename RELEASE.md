# Releasing `spectrum` to opam

This project currently uses a **manual release flow** with `make publish`.

## Prerequisites

- Work from your project opam switch
- Be logged in for `opam-publish` usage (GitHub auth as needed)
- Ensure your branch is up to date and clean

Optional setup of release tooling:

```sh
make setup
```

Optional release preview (no changes made):

```sh
make dry-run-release
```

## Release steps

1. **Bump version** in `dune-project`:

   ```dune
   (version X.Y.Z)
   ```

2. **Regenerate/check opam metadata**

   This repo has `(generate_opam_files true)`, so ensure `spectrum.opam` reflects the new version (e.g. after `dune build`).

3. **Run preflight checks**

   ```sh
   make release-check
   ```

   This verifies your git tree is clean and runs the test suite.

4. **Commit and push** release changes

   ```sh
   git add dune-project spectrum.opam CHANGES
   git commit -m "release X.Y.Z"
   git push
   ```

5. **Publish**

   ```sh
   make publish
   ```

   This runs:
   - `make release-check`
   - `git tag ${VERSION}`
   - `git push origin ${VERSION}`
   - `opam-publish`

6. **Complete opam-repository PR**

   Follow the `opam-publish` prompts and monitor CI on the generated opam-repository PR until merged.

## Notes

- CI in this repo (`.github/workflows/test.yml`) runs tests on pull requests only.
- `.github/release.yml` is changelog config, not an opam release workflow.
- `make publish` now checks whether the version tag already exists on `origin` (most important) and locally, and fails early with a clear message.
