# Solve one synthetic subject through linCmtA()/linCmtB() (test hook)

Replays rxode2's linear-only solve loop on local stand-ins for its
solver structs: each record advances the linear system from the previous
record (the model's value call), stores the amounts (and with linCmtB()
their sensitivities), then applies the record's dose. A second pass
re-queries every record as rxode2's output pass does.

## Usage

``` r
.linCmtHostSim(
  t,
  doseCmt,
  doseAmt,
  doseRate,
  theta,
  ncmt,
  oral0,
  trans,
  useB,
  sensType,
  ndiff,
  sensPhi,
  calls,
  linH,
  ss,
  ssTau,
  ssVar,
  ssCmt,
  lagMask,
  originMask,
  hPar,
  hStep,
  forwardMax
)
```

## Arguments

- t:

  record times (sorted)

- doseCmt:

  linCmt state receiving the record's dose (0 = depot when oral, else
  central), or -1 for an observation

- doseAmt:

  bolus amount (0 for none)

- doseRate:

  infusion rate change at the record (0 for none)

- theta:

  numeric matrix, one row of (p1, v1, p2, p3, p4, p5, ka) per record

- ncmt:

  number of compartments

- oral0:

  1 for a depot, else 0

- trans:

  parameterization code

- useB:

  `TRUE` for linCmtB() (sensitivities), `FALSE` for linCmtA()

- sensType:

  linCmtB() Jacobian method

- ndiff:

  linCmtB() derivative bit mask (0 = all)

- sensPhi:

  `linCmtSensPhi` control (-1 unset, 0, 1, 2)

- calls:

  integer matrix of extra `(which1, which2)` linCmtB() calls made after
  each record's value call in the output pass

- linH:

  finite-difference steps (length 7) for the FD methods

- ss:

  per-record steady-state type (0 none, 1 infinite infusion, 2 repeated
  infusion, 3 repeated bolus) evaluated at that record

- ssTau, ssVar:

  steady-state interval and infusion duration or bolus amount per record

- ssCmt:

  steady-state bolus compartment per record

- lagMask, originMask:

  the model's `op->linCmtLagMask` and `op->linCmtOriginMask`

- hPar, hStep:

  with `hPar >= 0`, an H-perturbed evaluation of parameter `hPar` by
  `hStep` (rxode2's step-size probe)

- forwardMax:

  `linCmtForwardMax`: the most points the forward difference methods use
  (rxode2's default is 2)

## Value

list with `val` (solve pass value per record), `lhs` (output pass
value), `state` (solve buffer, one row per record) and `calls` (output
pass results of `calls`, one row per record)
