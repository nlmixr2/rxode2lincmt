# Force the delta-keyed exponential memo on or off (tests/benchmarks)

Force the delta-keyed exponential memo on or off (tests/benchmarks)

## Usage

``` r
.linCmtDeltaMemo(on = -1L)
```

## Arguments

- on:

  integer: 1 forces the memo on, 0 forces it off, -1 (the default)
  follows the RX_LINCMT_DELTA_MEMO environment latch read at window-fill
  time

## Value

the previous setting, invisibly usable to restore it
