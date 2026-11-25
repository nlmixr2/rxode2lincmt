# Value-path constant cache against the uncached kernel (test hook)

Steps one kernel object through the rows of `par` with the theta-keyed
constant cache linCmtA() uses, and another through the uncached
evaluation, both from `alast0` with infusion `rate`.

## Usage

``` r
.linCmtValueCacheCheck(dt, par, ncmt, oral0, trans, alast0, rate)
```

## Arguments

- dt:

  row time steps

- par:

  numeric matrix, one row of (p1, v1, p2, p3, p4, p5, ka) per step

- ncmt:

  number of compartments

- oral0:

  1 for a depot, else 0

- trans:

  parameterization code

- alast0:

  starting amounts

- rate:

  infusion rates

## Value

list with `cached` and `direct`, the amounts after each step (one row
per step)
