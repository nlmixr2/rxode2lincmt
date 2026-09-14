# Advance a linear compartment model by one step

Advances the amounts of a one, two or three compartment linear model by
`dt` and returns the central concentration, optionally with its
derivatives. This is the per-row kernel behind rxode2's `linCmt()`.

## Usage

``` r
linCmtModelDouble(
  dt,
  p1,
  v1,
  p2,
  p3,
  p4,
  p5,
  ka,
  alastNV,
  rateNV,
  ncmt,
  oral0,
  trans,
  deriv,
  type,
  tau,
  tinf,
  amt,
  bolusCmt,
  ndiff,
  sensType = 3L,
  sensH = 0.001
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

- rateNV:

  zero-order rates into each compartment, in the same order

- ncmt:

  number of compartments, 1 to 3

- oral0:

  1 when the model has a depot compartment, otherwise 0

- trans:

  parameterization number

- deriv:

  logical; also return the derivatives

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

- sensType:

  derivative method: 3 or 30 forward-mode automatic differentiation, 32
  all directions in one forward-mode pass, 31 reverse mode, 100
  automatic choice, 1 and 2 forward and central differences with the
  kernel's own step, 10 and 20 forward and central differences with step
  `sensH`

- sensH:

  finite-difference step for `sensType` 10 and 20

## Value

list with `val` (central concentration) and `Alast` (carried state after
the step); with `deriv = TRUE` also `J` (Jacobian of the amounts) and
`Jg` (gradient of `val`)

## Examples

``` r
linCmtModelDouble(1, 2, 20, 0, 0, 0, 0, 0, 100, 0, 1L, 0L, 1L, FALSE,
                  0L, 0, 0, 0, 0L, 0L)
#> $val
#> [1] 4.524187
#> 
#> $Alast
#> [1] 90.48374
#> 
```
