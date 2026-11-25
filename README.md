# scip-rust

A thin wrapper around `rust-analyzer scip`.

## Usage

Make sure you have a working Rust toolchain (`cargo` and `rustc` on `PATH`) and
[`rust-analyzer`] installed. Then, from the root of your workspace:

``` sh
rust-analyzer scip .
```

That's really all it does. The [`scip-rust`] script in this repo is the same
command with a few preflight checks and toolchain fallbacks.

### Docker

The `ghcr.io/scip-code/scip-rust` image bundles everything:

``` sh
docker run --rm -v "$PWD:/work" ghcr.io/scip-code/scip-rust
```

### Nix

If you use Nix, run it straight from the flake:

``` sh
nix run github:scip-code/scip-rust
```

## Cutting releases

From the `main` branch, trigger the [release workflow] via **Actions → release →
Run workflow**, entering `M.N.P` as the version. It only releases a commit that
passed CI.

Every 4 weeks on Monday, the [scheduled release workflow] releases the next patch
version if the image changed since the last release, for example because
Renovate's lock file maintenance updated nixpkgs. Running it manually releases
the next patch version right away.

  [`rust-analyzer`]: https://rust-analyzer.github.io/book/installation.html
  [`scip-rust`]: ./scip-rust
  [release workflow]: https://github.com/scip-code/scip-rust/actions/workflows/release.yml
  [scheduled release workflow]: https://github.com/scip-code/scip-rust/actions/workflows/scheduled-release.yml
