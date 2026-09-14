## New submission

This is a new package.  It is being split out of 'rxode2' so that 'rxode2'
can pass its CRAN checks again.

## Why this package exists

'rxode2' 5.1.7 fails on r-release-macos-x86_64 and r-oldrel-macos-x86_64
because the check exceeds the 30-minute limit (1500 s to install plus 303 s
for the check on r-release).  Almost all of that time is compiling one file:
the analytic linear compartment solutions in `src/linCmt.cpp`, whose 'stan'
automatic-differentiation templates are instantiated for several scalar types.

Measured locally with clang -O2 -g, the flags the CRAN macOS builders use:

* 'rxode2' 5.1.7: about 1380 s of single-core compilation, of which
  `linCmt.cpp` alone was about 970 s (about 70%).
* 'rxode2' with that code moved here: about 310 s.
* 'rxode2lincmt': about 990 s, of which `src/linCmt.cpp` is about 950 s.

'rxode2lincmt' contains only that code: the one, two and three compartment
analytic solutions and their gradients, the eigen decompositions and the
derived-parameter conversions.  Moving it out lets 'rxode2' install in about a
fifth of the time and no longer depend on 'StanHeaders', 'RcppEigen' or
'RcppParallel'.  'rxode2' will Import and LinkingTo this package in its next
release (5.1.8), which is ready to submit once this package is accepted.

## How the two packages interact

'rxode2' previously merged 'rxode2parse', 'rxode2random' and 'rxode2et' back
into itself at CRAN's request, because those packages shared C struct layouts
and had to be rebuilt in lockstep.  This split is designed to avoid that:

* 'rxode2lincmt' does not include or depend on 'rxode2' or its headers.
* 'rxode2' reaches the compiled solutions through a documented, append-only
  table of external pointers (`inst/include/rxode2lincmtPtrs.h`), the same
  mechanism 'rxode2' already uses with 'rxode2ll', 'lotri' and 'PreciseSums'.
* 'rxode2' passes the offsets of the few solver fields the solutions read
  (`inst/include/rxode2lincmtHost.h`), so no struct layout is shared.  Types
  are checked when 'rxode2' compiles; nothing is checked at load, so either
  package can be updated without breaking the other.

The numerical results are unchanged: a 195-case comparison of the split
'rxode2' plus this package against 'rxode2' 5.1.7 is bitwise identical, and
'nlmixr2est' (a reverse dependency of 'rxode2', not rebuilt) gives identical
estimates.

'rxode2lincmt' uses the 'StanHeaders' and 'RcppParallel' headers only
(LinkingTo).  It neither links nor loads the TBB library, whose bundled copy
in 'RcppParallel' is what the gcc-UBSAN check reports for 'rxode2' 5.1.7.

The closed-form solutions follow the idea of the 'wnl' package by Kyun-Seop
Bae; the implementation here is different.

## Test environments

* local Ubuntu 24.04, R 4.6.1, gcc 14

## R CMD check results

0 errors | 0 warnings | 2 notes

* New submission.
* "Compilation used the following non-portable flag(s):
  -mno-omit-leaf-frame-pointer" comes from the local R installation's
  compiler flags, not from this package.

The package runs its own test suite without 'rxode2' installed.

## Reverse dependencies

There are no reverse dependencies yet.  'rxode2' will depend on this package
in its next release.
