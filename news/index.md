# Changelog

## rxode2lincmt 0.1.1

### New features

- `linCmt()` FOCEi fits spend less time per row: the output pass that
  runs after each solved interval now takes the thin value path instead
  of restoring the full Jacobian, the AD path copies the requested
  parameters instead of running the scaling setup, and the value-memo
  check runs before the rest of the per-row work. Results are bitwise
  unchanged ([\#2](https://github.com/nlmixr2/rxode2lincmt/issues/2)).

### Bug fixes

- The last-row value memo of `linCmt()` never hit inside an ‘nlmixr2est’
  fit, because ‘nlmixr2est’ leaves the finite-difference step NaN and
  NaN never equals itself; every repeated call the model makes for a row
  recomputed it. The memo keys now compare bitwise
  ([\#2](https://github.com/nlmixr2/rxode2lincmt/issues/2)).

## rxode2lincmt 0.1.0

CRAN release: 2026-09-24

### New features

- Initial release. The analytic one, two and three compartment linear
  solutions, their ‘stan’ gradients, the eigen decompositions
  ([`solComp2()`](https://nlmixr2.github.io/rxode2lincmt/reference/solComp2.md),
  [`solComp3()`](https://nlmixr2.github.io/rxode2lincmt/reference/solComp3.md))
  and the derived-parameter conversions behind `rxode2::rxDerived()`
  moved here from ‘rxode2’, so ‘rxode2’ no longer compiles ‘stan’.
  ‘rxode2’ reaches the compiled kernels through an external-pointer
  table and hands this package the struct offsets it needs, so neither
  package shares struct layouts with the other.

- The package neither links nor loads the TBB library: the ‘stan’
  autodiff tapes are created per thread here, so ‘RcppParallel’ is
  needed only for its headers.

- The closed-form solutions follow the idea of the ‘wnl’ package by
  Kyun-Seop Bae; the implementation here is different.
