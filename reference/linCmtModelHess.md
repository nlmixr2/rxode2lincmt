# Advance a linear compartment model one step with exact Hessians

Like
[`linCmtModelDouble()`](https://nlmixr2.github.io/rxode2lincmt/reference/linCmtModelDouble.md)
with `deriv = TRUE`, but also carries and returns the Hessian of each
amount, and of the central concentration, with respect to the full
parameter vector `(p1, v1, ..., ka)`, by nested forward-mode automatic
differentiation (rxode2lincmt#17).

## Usage

``` r
linCmtModelHess(
  dt,
  p1,
  v1,
  p2,
  p3,
  p4,
  p5,
  ka,
  alastNV,
  alastH,
  rateNV,
  ncmt,
  oral0,
  trans,
  type = 0L,
  tau = 0,
  tinf = 0,
  amt = 0,
  bolusCmt = 0L,
  ndiff = 0L,
  quadCarry = TRUE
)
```

## Arguments

- dt:

  time step

- p1, v1, p2, p3, p4, p5:

  parameters in the `trans` parameterization (see
  [`linCmtMicros()`](https://nlmixr2.github.io/rxode2lincmt/reference/linCmtMicros.md))

- ka:

  absorption rate constant (used when `oral0` is 1)

- alastNV:

  amounts at the start of the step (depot first when `oral0` is 1, then
  central and peripherals); with `deriv = TRUE` followed by their
  parameter sensitivities

- alastH:

  Hessians of the starting amounts: `m * n * n` values, one column-major
  `n x n` block per amount (`m` amounts, `n` parameters)

- rateNV:

  zero-order rates into each compartment, in the same order

- ncmt:

  number of compartments, 1 to 3

- oral0:

  1 when the model has a depot compartment, otherwise 0

- trans:

  parameterization number

- type:

  0 for a regular step; 1 and 2 steady-state infusion, 3 steady-state
  bolus

- tau:

  steady-state dosing interval

- tinf:

  steady-state infusion duration

- amt:

  steady-state bolus amount

- bolusCmt:

  steady-state bolus compartment

- ndiff:

  differentiation bit mask as used by rxode2 (`ka` 1, `p1` 2, `v1` 4,
  `p2` 8, `p3` 16, `p4` 32, `p5` 64)

- quadCarry:

  logical; use the quadratic carry-forward of the starting amounts.
  `FALSE` uses the linear carry of the first-order path.

## Value

list with `val` (central concentration), `Jg` (its gradient), `Hc` (its
`n x n` Hessian), `fx` (amounts after the step), `J` (`m x n` Jacobian),
`H` (`n x n x m` array of amount Hessians) and `Alast` (carried state
for the next call)
