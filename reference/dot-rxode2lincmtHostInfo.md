# Inspect the registered host table

Test hook: the struct offsets currently held (-1 before registration)
and whether each host function has been bound.

## Usage

``` r
.rxode2lincmtHostInfo()
```

## Value

list with `offsets` (integer) and `fns` (named logical)

## Examples

``` r
.rxode2lincmtHostInfo()$fns
#>      getTime rxThreadSlot   getRxSolve 
#>        FALSE        FALSE        FALSE 
```
