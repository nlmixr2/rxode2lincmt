# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when
working with code in this repository.

## Overview

**rxode2lincmt** holds the Stan-based linear compartment code that used to
live in rxode2: the analytic 1-3 compartment solutions and their gradients
(`src/linCmt.cpp`, `src/linCmt.h`, `src/linCmtDualN.h`), the eigen
decompositions (`src/solComp.*`), the macro-to-micro constant conversion
(`src/macros2micros.*`) and the derived-parameter engine behind
`rxode2::rxDerived()` (`src/rxDerived.cpp`).  It was split out so rxode2's
installation does not compile Stan (rxode2 5.1.7 exceeded CRAN's 30-minute
macOS x86_64 check limit; `linCmt.cpp` alone was ~58% of its compile time).

rxode2 Imports this package.  This package must NEVER depend on rxode2
(no Imports, LinkingTo or Suggests), which would create a cycle.

## Build and Development Commands

```sh
# Install into a private library (never the shared one other sessions use)
R CMD INSTALL -l ~/R/lib-lincmt-dev .
```

```r
devtools::document()   # roxygen + NAMESPACE
Rcpp::compileAttributes(".")  # then update src/init.c arities by hand
```

### Tests

Run filtered tests only; never the whole suite as a habit.

```sh
find src -name "*.so" -o -name "*.o" | xargs rm -f 2>/dev/null; NOT_CRAN=true Rscript -e "devtools::test(filter='modelDouble')"
```

The test suite must pass without rxode2 installed.

### Clean objects after header changes

R's incremental build does not track header dependencies.  After editing any
header in `src/` or `inst/include/`, remove `src/*.o` and `src/*.so` before
rebuilding.

## Architecture

### Two tables between rxode2 and this package

1. **lincmt table (this package -> rxode2).**  `src/ptr.c`
   `_rxode2lincmt_ptr()` returns external pointers to `linCmtA`, `linCmtB`,
   `ensureLinCmtA`, `ensureLinCmtB`, `linCmtBindFree`, `linCmtScaleInitPar`,
   `linCmtScaleInitN`, `linCmtZeroJac`, `linCmtFreeInd` (R:
   `.rxode2lincmtPtr()`).  rxode2 reads it with the reader in
   `inst/include/rxode2lincmtPtrs.h`.
2. **host table (rxode2 -> this package).**  rxode2 calls
   `.rxode2lincmtIniHost()` with the `offsetof()` of every solver-struct field
   linCmt uses plus host functions (`getTime`, rxode2's thread-slot function,
   `getRxSolve`).  The single source of truth is the X-macro list in
   `inst/include/rxode2lincmtHost.h`; `src/host.c` receives it.

rxode2 calls both from `.linkAll()` in its `.onLoad()`, host table first.

> [!IMPORTANT]
> **Both tables are APPEND-ONLY and are NEVER validated at load.**  Never
> rename, reorder, remove or repurpose a slot, a label, or an X-macro row --
> a released rxode2 built against the old order must keep working with a
> newer rxode2lincmt.  Only append.  Never add a version, name, length or
> type check to `_rxode2lincmt_ptr()`, `_rxode2lincmt_iniHost()`, or any
> load path: rxode2 (and every package that imports it) loads through them,
> and one failing check takes all of them down at CRAN.  Assert invariants in
> tests instead.

### Struct access through the offset table

This package never includes rxode2's struct headers.  `rx_solve`,
`rx_solving_options` and `rx_solving_options_ind` are opaque here
(`src/lcHost.h`), and every field is read through the offsets rxode2 passed:

- Write `IND(ind, f)`, `OPT(op, f)`, `RXS(rx, f)` and `RX_IND(rx, id)` (for
  `&rx->subjects[id]`) -- never `ind->f`.  A field not in
  `RXLC_HOST_FIELDS` does not compile; add a row (append only).
- Per-field typedefs keep array types, so `sizeof(IND(ind, linCmtOrigin))`
  and `memcpy` behave exactly as on the real struct.
- A field appended after the first release may be missing when an older
  rxode2 registers the table: read it only through `LC_HAS(s, f)` with a
  fallback.
- Field types are enforced only at rxode2's compile time
  (`RXLC_HOST_STATIC_CHECKS`), never at load.
- Before registration every offset is -1 and every host function is a local
  fallback (no NULL); only rxode2-driven solves touch the structs.

### Memory and threads across the two DLLs

- Anything linCmt allocates (`linCmtRateHist`, `linCmtOriginHist` via
  `realloc`, `linCmtBind` via `new`) is freed only here, through
  `linCmtFreeInd` / `linCmtBindFree`.  Never free or reallocate a linCmt
  buffer in rxode2 or a linCmt buffer's owner here from rxode2's memory -- on
  Windows the two DLLs can use different heaps.
- Per-thread slots always come from `rx_get_thread()`, which calls rxode2's
  thread-slot function.  Do not call `omp_get_thread_num()` for slot
  selection: this DLL's OpenMP runtime can number threads created by rxode2
  differently.
- `(Rf_error)` inside `linCmtB` and `Rcpp::stop` in
  `linCmtStan::setModelType` can fire inside rxode2's OpenMP solve; this is
  pre-existing behavior inherited from rxode2, not something to extend.

### Stale pointers after reloading (development)

Reinstalling or `load_all()`-ing this package in a live session leaves
rxode2's copied addresses pointing at the old DLL.  rxode2 registers a
`packageEvent("rxode2lincmt", "onLoad")` hook that re-links it; if in doubt,
restart R or run `rxode2:::.linkAll()` interactively (never in code).

### Bitwise parity

The kernels must give bitwise identical results to rxode2 5.1.7.  That
depends on keeping the same compile flags: the `@O2@` compiler probe in
`inst/tools/workaround.R` (`-O3 -fno-math-errno -mtune=native` for gcc/clang),
`-DSTAN_THREADS`, `-DEIGEN_DONT_PARALLELIZE` and
`-DBOOST_DISABLE_ASSERTS`.  Changing any of them is a numeric change.

### Stan / TBB build

`inst/tools/workaround.R` writes `src/Makevars(.win)` with header-only Stan
flags (`-DSTAN_THREADS`, the RcppParallel TBB and StanHeaders include
directories) built with `system.file()`.  Nothing links or loads TBB:
`src/lcStanCompat.h` pre-defines the `init_chainablestack.hpp` guard so stan's
TBB `ad_tape_observer` never compiles; `linCmt.cpp` creates the loading
thread's AD tape (`RXODE2_NO_STAN_TBB_OBSERVER`) and `linCmtRevTapeInit()`
every other thread's.  Loading TBB is what CRAN's gcc-UBSAN check reports, so
never import 'RcppParallel', call `StanHeaders:::CxxFlags()`/`LdFlags()` (they
load it) or add `-ltbb`; `tests/testthat/test-no-tbb.R` guards this.

## R Code Style

- **Exported functions**: `camelCase` (e.g., `solComp2`, `linCmtModelDouble`)
- **Internal/non-exported functions and local variables**: `.camelCase`
- Exported test/interop hooks used by rxode2 are dot-named and
  `@keywords internal` (e.g., `.rxode2lincmtPtr`, `.linCmtSeqStats`)
- Avoid `snake_case` for new names
- **Never write `pkg:::foo`** in package code, tests or `bench/`.  Tests run
  in the package namespace; call internals by bare name.  In `bench/`, bind
  with `utils::getFromNamespace()`.
- ASCII only, American English.

## C/C++ Conventions

- Use `(Rf_error)(...)` (wrapped in parens) rather than `Rf_error(...)`
- C files use `#define STRICT_R_HEADERS` and `#define USE_FC_LEN_T`; C++
  files use `R_NO_REMAP` where R headers come directly
- Include `omp.h` only through `src/lcOmp.h` (it hides R's `match` macro,
  which breaks LLVM's `omp.h`)
- In C++ use `rxProtect` (`src/rxProtect.h`) instead of PROTECT/UNPROTECT
- `src/init.c` is the MANUAL `.Call` registration table with hardcoded
  arities.  When an Rcpp export is added or changes its argument count, run
  `Rcpp::compileAttributes(".")` AND update `src/init.c`; skipping the
  latter fails only at run time ("Incorrect number of arguments").

## Documentation and Comment Style

- Keep comments and documentation terse; state the fact, not the story.
- Roxygen: one compact description paragraph; keep every `@param`,
  `@return`, `@author`, `@export`, `@keywords` tag.
- `NEWS.md` per version (`# rxode2lincmt X.Y.Z`): `## New features` then
  `## Bug fixes`; past-tense bullets, a sentence or two.
- ASCII only (CRAN): `--` for dashes, `->` for arrows, straight quotes.
