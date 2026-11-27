# Changelog

## rxode2lincmt (development version)

### New features

- The `linCmt()` sensitivity carry is read from rxode2’s solve buffer
  (`ind->solve`) when rxode2 sends its carry states (the new host-table
  rows `numLinCarry`, `linCmtCarryRow` and `n_all_times`), sized to each
  model, so it has no cap;
  [`.linCmtCarryMaxPairs()`](https://nlmixr2.github.io/rxode2lincmt/reference/dot-linCmtCarryMaxPairs.md)
  reports `.Machine$integer.max` then. With an rxode2 that does not send
  them the carry stays in the fixed 8-pair array, as before.

### Bug fixes

- At a confluence the one to three compartment solutions divided by a
  vanishing difference of rates: an absorption rate at a disposition
  rate, two nearly equal disposition rates, a near-zero elimination
  under an infusion, a disposition rate far below the largest – in the
  time-propagation solutions and the steady states alike. That gave a
  `NaN` amount (two and three compartment oral models, oral steady
  states), a wrong `ka` gradient at an exact one compartment confluence,
  and values and derivatives that lost their digits near one. Inside
  those bands (one rule over the rates the solution is built from) the
  step and the steady states are now computed from the matrix
  exponential of the compartment generator, which has no rate
  differences and no eigenvalues; outside them the closed forms run
  unchanged (bitwise). Every case of a 60-digit reference now matches to
  1e-10 in value and 1e-9 in gradient
  ([\#18](https://github.com/nlmixr2/rxode2lincmt/issues/18)).
- Internal test hook
  [`.linCmtHostSim()`](https://nlmixr2.github.io/rxode2lincmt/reference/dot-linCmtHostSim.md)
  solves a synthetic subject through `linCmtA()`/`linCmtB()` on stand-in
  solver structs, so the solver paths are tested without rxode2.

### Bug fixes

- The per-compartment dose-time and bioavailability sensitivities
  (`linCmtB()` `which1 = -9` and `-10`) are no longer `NA` at a record
  the solve does not advance: one at the same time as the record before
  it, such as an observation at a dose time. Such a record had no
  decomposition of its own; it now takes the last advanced record’s,
  plus the doses given at that time. nlmixr2est’s FOCEi reads the `-10`
  sensitivity at every observation, so a `linCmt()` model with an eta on
  `f()` failed every subject that had a sample at a dose time, and its
  fit returned a constant objective. At an infusion start the dose-time
  read uses the started rate; a model tracking no origin still reads
  `NA`.

- [`linCmtModelDouble()`](https://nlmixr2.github.io/rxode2lincmt/reference/linCmtModelDouble.md)
  no longer crashes R with the finite-difference `sensType` values 1, 2,
  10 and 20: it now computes the base value first, as `linCmtB()` does,
  and all four use the step `sensH`.

- The four-point forward difference that `linCmt()` finite-difference
  gradients fall back to with `linCmtForwardMax = 3` used the
  coefficient 6 instead of 2 on its last point, so a suspect gradient
  came out wrong. The default (`linCmtForwardMax = 2`) is unchanged.

## rxode2lincmt 0.1.1

### New features

- `linCmtB()` now gives second-order sensitivities: `which1 = -20` reads
  the Hessian of an amount and `which1 = -21` that of the central
  concentration, over the full parameter order. They are kept, with a
  quadratic carry of the dose history, only for a model that asks for
  them (`ndiff` bit 128), so other models are unchanged. A modeled
  bioavailability is followed (it scales a parameter-free dose amount).
  Rows whose carry these parameter-space Hessians do not follow –
  finite-difference sensitivities, a modeled lag, rate or duration,
  replace and multiply records, parameters that change between records,
  and any row advanced on a path that keeps no Hessians – read `NA`,
  never a silent zero
  ([\#17](https://github.com/nlmixr2/rxode2lincmt/issues/17)).

- [`linCmtModelHess()`](https://nlmixr2.github.io/rxode2lincmt/reference/linCmtModelHess.md)
  advances one step with the value, Jacobian and Hessians, the
  second-order counterpart of
  [`linCmtModelDouble()`](https://nlmixr2.github.io/rxode2lincmt/reference/linCmtModelDouble.md)
  ([\#17](https://github.com/nlmixr2/rxode2lincmt/issues/17)).

- An eta-space second-order carry, driven by `linCmtB()` sentinels
  (`which1 = -30` to `-38`), gives the exact first and second
  derivatives of the amounts and the concentration in the random effects
  when the parameters change between records (a time-varying covariate)
  and through a modeled bioavailability on boluses. Each row passes its
  own `dp/deta` and `d2p/deta2` (and `dF/deta`, `d2F/deta2`); the step
  is differentiated through them, and the interval takes the parameters
  the solve itself used, so `locf` and `nocb` interpolation are both
  followed. The generated model has to emit the sentinels; this is the
  runtime the estimator’s code generation builds on
  ([\#19](https://github.com/nlmixr2/rxode2lincmt/issues/19)).

- The second-order steps can be switched per thread: the C callable
  `linCmtSetHessThread()` (registered for `R_GetCCallable()`, detected
  by the internal `.linCmtHessThread()`) says, on the solving thread,
  whether the model being solved reads them. `rx->ndiff` is one field
  shared by every model an estimator solves concurrently, so an
  estimator that keeps the second-order bit on for all of them uses this
  to spare the models that never read a Hessian. The second-order
  history also starts over when a subject is solved again, and a record
  at the initial state reads zero rather than `NA`.

- `linCmt()` FOCEi fits spend less time per row: the output pass that
  runs after each solved interval now takes the thin value path instead
  of restoring the full Jacobian, the AD path copies the requested
  parameters instead of running the scaling setup, and the value-memo
  check runs before the rest of the per-row work. Results are bitwise
  unchanged ([\#2](https://github.com/nlmixr2/rxode2lincmt/issues/2)).

- `linCmt()` value-only solves (SAEM, `rxSolve()` simulation, pred-only
  solves) return an already-solved row before any model setup. Results
  are bitwise unchanged
  ([\#9](https://github.com/nlmixr2/rxode2lincmt/issues/9)).

- `linCmt()` value-only solves no longer allocate on each computed row.
  Results are bitwise unchanged
  ([\#9](https://github.com/nlmixr2/rxode2lincmt/issues/9)).

- `linCmt()` value-only solves compute the micro-constants and the 2-
  and 3-compartment eigen-decomposition once per parameter set instead
  of on every row. Results are bitwise unchanged
  ([\#9](https://github.com/nlmixr2/rxode2lincmt/issues/9)).

### Bug fixes

- The `linCmt()` sensitivity carry, which ‘nlmixr2est’ uses for the
  FOCEi gradient of a `linCmt()` parameter with a time-varying
  covariate, now restarts at a reset (EVID 3, and the reset an EVID 4
  begins with). The reset zeroes the compartments, but the carried
  sensitivities and their trackers kept their values from before it, so
  such a fit with a reset was off the same model written as ODEs (0.063
  in the objective with an EVID 4 under nocb). A replace (EVID 5) or
  multiply (EVID 6) record, from the data or pushed by `evid_()`, now
  zeroes or scales the replaced compartment’s carried sensitivities,
  which used to keep their values. The carried gradient after such a
  record is exact only together with `linCmtEventJac()`, which makes
  this package’s own Jacobian follow the event; without it, it is no
  worse than before. With `f()` or `alag()` modeled on the compartment
  the carry does not know a multiply’s factor and leaves that
  compartment’s sensitivities as before.

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
