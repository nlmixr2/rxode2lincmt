# Derived linear compartment parameters (engine for `rxode2::rxDerived()`)

Low-level entry point: rxode2's `rxDerived()` parses the parameter names
and calls this with the compartment count, parameterization and a list
of parameter vectors. Use `rxode2::rxDerived()` instead of calling it
directly.

## Usage

``` r
.calcDerived(ncmt, oral, w2, trans, inp, digits = 0)
```

## Arguments

- ncmt:

  number of compartments (1-3, double)

- oral:

  oral flag (double)

- w2:

  parser weight flag (double)

- trans:

  parameterization number (double)

- inp:

  list of parameter vectors in parser order

- digits:

  significant digits to round to (0 for no rounding)

## Value

data frame of derived parameters
