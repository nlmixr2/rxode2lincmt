# Micro-constants of a linear compartment model

Converts one parameter set, in any of the `linCmt()` parameterizations,
to the central volume and micro-constants that the analytic solutions
use.

## Usage

``` r
linCmtMicros(p1, v1, p2 = 0, p3 = 0, p4 = 0, p5 = 0, ncmt, trans = 1L)
```

## Arguments

- p1:

  first parameter (for example clearance or `k`)

- v1:

  central volume (or its parameterization-specific counterpart)

- p2:

  second parameter (two and three compartments)

- p3:

  third parameter (two and three compartments)

- p4:

  fourth parameter (three compartments)

- p5:

  fifth parameter (three compartments)

- ncmt:

  number of compartments, 1 to 3

- trans:

  parameterization number (see Details)

## Value

named numeric vector: `v`, `k`, and for two or more compartments `k12`,
`k21`, and for three compartments `k13`, `k31`

## Details

Supported `trans` values: one compartment 1 (`cl`, `v`), 2 (`k`, `v`),
10 (`alpha`, `A` with `v1` holding `A`), 11 (`alpha`, `v`); two
compartments 1 (`cl`, `v`, `q`, `vp`), 2 (`k`, `v`, `k12`, `k21`), 3
(`cl`, `v`, `q`, `vss`), 4 (`alpha`, `beta`, `k21`), 5 (`alpha`, `beta`,
`aob`), 10, 11; three compartments 1 (`cl`, `v`, `q`, `vp`, `q2`,
`vp2`), 2 (`k`, `v`, `k12`, `k21`, `k13`, `k31`), 10, 11.

## Author

Matthew L. Fidler

## Examples

``` r
linCmtMicros(p1 = 2, v1 = 20, ncmt = 1)
#>    v    k 
#> 20.0  0.1 
linCmtMicros(p1 = 2, v1 = 20, p2 = 3, p3 = 40, ncmt = 2)
#>      v      k    k12    k21 
#> 20.000  0.100  0.150  0.075 
```
