# rxode2lincmt 0.1.1

## New features

- `linCmt()` FOCEi fits spend less time per row: the output pass that runs
  after each solved interval now takes the thin value path instead of
  restoring the full Jacobian, the AD path copies the requested parameters
  instead of running the scaling setup, and the value-memo check runs before
  the rest of the per-row work.  Results are bitwise unchanged (#2).

## Bug fixes

- The `linCmt()` sensitivity carry, which 'nlmixr2est' uses for the FOCEi
  gradient of a `linCmt()` parameter with a time-varying covariate, now
  restarts at a reset (EVID 3, and the reset an EVID 4 begins with).  The
  reset zeroes the compartments, but the carried sensitivities and their
  trackers kept their values from before it, so such a fit with a reset
  was off the same model written as ODEs (0.063 in the objective with an
  EVID 4 under nocb).  A replace (EVID 5) or multiply (EVID 6) record, from
  the data or pushed by `evid_()`, now zeroes or scales the replaced
  compartment's carried sensitivities, which used to keep their values.
  The carried gradient after such a record is exact only together with
  `linCmtEventJac()`, which makes this package's own Jacobian follow the
  event; without it, it is no worse than before.  With `f()` or `alag()`
  modeled on the compartment the carry does not know a multiply's factor
  and leaves that compartment's sensitivities as before.

- The last-row value memo of `linCmt()` never hit inside an 'nlmixr2est' fit,
  because 'nlmixr2est' leaves the finite-difference step NaN and NaN never
  equals itself; every repeated call the model makes for a row recomputed
  it.  The memo keys now compare bitwise (#2).

# rxode2lincmt 0.1.0

## New features

- Initial release.  The analytic one, two and three compartment linear
  solutions, their 'stan' gradients, the eigen decompositions (`solComp2()`,
  `solComp3()`) and the derived-parameter conversions behind
  `rxode2::rxDerived()` moved here from 'rxode2', so 'rxode2' no longer
  compiles 'stan'.  'rxode2' reaches the compiled kernels through an
  external-pointer table and hands this package the struct offsets it needs,
  so neither package shares struct layouts with the other.

- The package neither links nor loads the TBB library: the 'stan' autodiff
  tapes are created per thread here, so 'RcppParallel' is needed only for
  its headers.

- The closed-form solutions follow the idea of the 'wnl' package by
  Kyun-Seop Bae; the implementation here is different.
