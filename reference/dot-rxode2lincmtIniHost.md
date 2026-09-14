# Register the host table from rxode2

rxode2 calls this from its `.onLoad()` with the struct offsets and host
functions described in `inst/include/rxode2lincmtHost.h`. Nothing is
validated; values are copied with bounds limits only.

## Usage

``` r
.rxode2lincmtIniHost(host)
```

## Arguments

- host:

  list built by rxode2 (offsets followed by external pointers)

## Value

`NULL`, invisibly
