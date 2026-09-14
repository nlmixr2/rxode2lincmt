# Read (and optionally reset) the linCmt() carry-advance fast-path counters

Read (and optionally reset) the linCmt() carry-advance fast-path
counters

## Usage

``` r
.linCmtCarryFastStats(reset = FALSE)
```

## Arguments

- reset:

  logical; when TRUE zero the counters after reading

## Value

named numeric vector: advCalls (every which1=-5 invocation), advFast
(subset that took the constant-theta skip)
