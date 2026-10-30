# rxode2lincmt (development version)

## Bug fixes

- The `linCmt()` sensitivity carry reads its column count from the
  registered 'rxode2' at run time (`.linCmtCarryMaxPairs()`) instead of
  compiling in 8.  Any 'rxode2' with 1 to 32 carry columns works with this
  package; one with more, or with none, is refused at load with a message.
  The carry advance also multiplies only the columns a model uses, and the
  restart at a reset clears only those, at the host's stride.

## New features

- `linCmtCarryReset()`, slot 9 of the pointer table (read with
  `iniRxode2lincmtCarryReset()`), zeroes only the carry columns a subject
  has written since its last reset, so 'rxode2' need not clear the whole
  array for every subject of every solve.

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
  compartment's carried sensitivities; they used to keep their values, and
  the carried gradient after the event was off by 78% (with rxode2lincmt's
  own Jacobian fix for these events; with `f()` modeled on the compartment a
  multiply gives NA).

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
