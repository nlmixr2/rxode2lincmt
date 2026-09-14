## New submission

'rxode2lincmt' holds the Stan-based linear compartment solutions, their
automatic-differentiation gradients and the related eigen decompositions and
derived-parameter conversions that were previously compiled inside 'rxode2'.

'rxode2' 5.1.7 exceeded the 30-minute check limit on
r-release-macos-x86_64 (1500 s install + 303 s check); the Stan
instantiations in its linCmt.cpp were about 70% of its compile time.  With
this code split out, 'rxode2' (which will Import this package in its next
release) compiles in about a quarter of its previous time.

## Compile time

Measured locally with clang -O2 -g, the flags the CRAN macOS builders use:

* rxode2 5.1.7: about 1380 s of single-core compilation, of which linCmt.cpp
  was about 970 s.
* rxode2lincmt: about 990 s, of which src/linCmt.cpp is about 950 s.
* rxode2 after the split: about 310 s.

## Test environments

* local Ubuntu 24.04, R 4.6.1, gcc 14

## R CMD check results

0 errors | 0 warnings | 2 notes

* New submission.  The GitHub URLs in DESCRIPTION resolve once the
  repository is public.
* "Compilation used the following non-portable flag(s):
  -mno-omit-leaf-frame-pointer" comes from the local R installation's
  compiler flags, not from this package.

## Reverse dependencies

This is a new package; there are no reverse dependencies yet.
