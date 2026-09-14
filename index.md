# rxode2lincmt

`rxode2lincmt` provides the analytic one, two and three compartment
linear pharmacokinetic solutions and their parameter gradients that
[rxode2](https://nlmixr2.github.io/rxode2/)‘s `linCmt()` uses. The
gradients come from ’stan’ automatic differentiation.

This code used to be compiled inside ‘rxode2’. It lives in its own
package so that installing ‘rxode2’ does not compile ‘stan’: ‘rxode2’
imports `rxode2lincmt` and calls the compiled kernels through an
external-pointer table. Most users never call `rxode2lincmt` directly;
they write `linCmt()` in an ‘rxode2’ or ‘nlmixr2’ model.

The closed-form solutions follow the idea of the
[wnl](https://CRAN.R-project.org/package=wnl) package by Kyun-Seop Bae,
though the implementation here is different.

## Installation

You can install the development version of `rxode2lincmt` from
[GitHub](https://github.com/nlmixr2/rxode2lincmt) with:

``` r

# install.packages("devtools")
devtools::install_github("nlmixr2/rxode2lincmt")
```

Compiling the ‘stan’-based solutions takes a while.

## Examples

The eigenvalues and coefficient matrices of a two compartment model from
its micro-constants:

``` r

library(rxode2lincmt)
solComp2(k10 = 0.1, k12 = 3, k21 = 1)
#> $L
#> [1] 4.07546291 0.02453709
#> 
#> $C1
#>            [,1]      [,2]
#> [1,]  0.7592000 0.2408000
#> [2,] -0.7405714 0.7405714
#> 
#> $C2
#>            [,1]      [,2]
#> [1,] -0.2468571 0.2468571
#> [2,]  0.2408000 0.7592000
```

The micro-constants of a two compartment model given clearance and
volume parameters:

``` r

linCmtMicros(p1 = 2, v1 = 20, p2 = 3, p3 = 40, ncmt = 2)
#>      v      k    k12    k21 
#> 20.000  0.100  0.150  0.075
```

One step of the per-row kernel: the concentration one time unit after a
100-unit bolus into a one compartment model with clearance 2 and volume
20, which matches the closed form `100 / 20 * exp(-2 / 20)`:

``` r

step <- linCmtModelDouble(dt = 1, p1 = 2, v1 = 20, p2 = 0, p3 = 0, p4 = 0, p5 = 0,
                          ka = 0, alastNV = 100, rateNV = 0, ncmt = 1L, oral0 = 0L,
                          trans = 1L, deriv = FALSE, type = 0L, tau = 0, tinf = 0,
                          amt = 0, bolusCmt = 0L, ndiff = 0L)
step$val
#> [1] 4.524187
100 / 20 * exp(-2 / 20)
#> [1] 4.524187
```
