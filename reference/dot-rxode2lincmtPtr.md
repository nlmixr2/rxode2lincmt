# External pointers to the linear compartment entry points

rxode2 reads this list from its `.onLoad()` and calls the linear
compartment kernels through it; see `inst/include/rxode2lincmtPtrs.h`
for the consumer contract. The list is append-only and its order is
fixed.

## Usage

``` r
.rxode2lincmtPtr()
```

## Value

named list of external pointers

## Examples

``` r
names(.rxode2lincmtPtr())
#> [1] "linCmtA"            "linCmtB"            "ensureLinCmtA"     
#> [4] "ensureLinCmtB"      "linCmtBindFree"     "linCmtScaleInitPar"
#> [7] "linCmtScaleInitN"   "linCmtZeroJac"      "linCmtFreeInd"     
```
