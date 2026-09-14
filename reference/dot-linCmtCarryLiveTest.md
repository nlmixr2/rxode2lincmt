# Drive linCmtB() carry sentinels on a solved subject (test hook)

Replays linCmtB() calls for one subject of the most recent rxode2 solve
in the same session, the way that subject's output pass would, so tests
can check the carry sentinels. Needs rxode2 to be loaded and a solve to
have run.

## Usage

``` r
.linCmtCarryLiveTest(
  id,
  t,
  tPrior,
  theta,
  ncmt,
  oral0,
  trans,
  which1,
  which2,
  addVal = NULL
)
```

## Arguments

- id:

  0-based subject index in the most recent solve

- t:

  output time of each row

- tPrior:

  time of the preceding row (0 for the first row)

- theta:

  numeric matrix with one row per element of `t` and 7 columns: p1, v1,
  p2, p3, p4, p5, ka

- ncmt:

  number of compartments, 1 to 3

- oral0:

  1 when the model has a depot compartment, otherwise 0

- trans:

  parameterization number

- which1:

  per-row `which1` argument passed to linCmtB()

- which2:

  per-row `which2` argument passed to linCmtB()

- addVal:

  for rows with `which1 = -7`, the value to add (passed in the p2
  argument); `NULL` for none

## Value

numeric vector of linCmtB() results, one per row
