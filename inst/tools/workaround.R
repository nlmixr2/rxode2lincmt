## Writes src/Makevars (src/Makevars.win on Windows) from src/Makevars.in:
## optimization flags and header paths.  The optimization probe and the Stan
## defines are the ones rxode2 used when it compiled this code, kept identical
## for bitwise parity.

compilerPath <- tools::Rcmd("config CC", stdout=TRUE)

# To distinguish between them, check the version output
versionInfo <- try(system(paste(compilerPath, "--version"), intern = TRUE))
if (inherits(versionInfo, "try-error")) {
  .o2 <- "-O2 "
} else if (any(grepl("clang", versionInfo, ignore.case = TRUE))) {
  .o2 <- "-O3 -fno-math-errno -mtune=native "
} else if (any(grepl("gcc", versionInfo, ignore.case = TRUE))) {
  .o2 <- "-O3 -fno-math-errno -mtune=native "
} else {
  .o2 <- "-O2 "
}

.in <- suppressWarnings(readLines("src/Makevars.in"))
.in <- gsub("@O2@", .o2, .in)
.in <- gsub("@BH@", file.path(find.package("BH"), "include"), .in)
.in <- gsub("@RCPP@", file.path(find.package("Rcpp"), "include"), .in)
.in <- gsub("@EG@", file.path(find.package("RcppEigen"), "include"), .in)

# Stan and TBB headers only; nothing links TBB (src/lcStanCompat.h keeps stan's
# TBB tape observer out of the build).  These are the flags
# StanHeaders:::CxxFlags() emits, built with system.file() because calling it
# loads 'StanHeaders' and so 'RcppParallel', which loads the TBB library.
.tbbInc <- Sys.getenv("TBB_INC")
if (dir.exists(.tbbInc)) {
  .tbbInc <- normalizePath(.tbbInc)
} else {
  .tbbInc <- system.file("include", package = "RcppParallel", mustWork = TRUE)
}
.sh <- paste0("-I", shQuote(.tbbInc), " -D_REENTRANT -DSTAN_THREADS",
              if (file.exists(file.path(.tbbInc, "tbb", "version.h"))) " -DTBB_INTERFACE_NEW",
              " -@ISYSTEM@'", system.file("include", package = "StanHeaders", mustWork = TRUE), "'",
              " -@ISYSTEM@'", system.file("include", "src", package = "StanHeaders", mustWork = TRUE), "'")
.in <- gsub("@SH@", gsub("-I", "-@ISYSTEM@", .sh), .in)

if (.Platform$OS.type == "windows") {
  .makevars <- file("src/Makevars.win", "wb")
  .i <- "I"
} else {
  .makevars <- file("src/Makevars", "wb")
  if (any(grepl("Pop!_OS", utils::osVersion, fixed = TRUE)) ||
        any(grepl("Ubuntu", utils::osVersion, fixed = TRUE))) {
    .i <- "isystem"
  } else {
    .i <- "I"
  }
}

writeLines(gsub("@ISYSTEM@", .i, .in), .makevars)
close(.makevars)
