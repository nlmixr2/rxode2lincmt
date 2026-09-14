## Writes src/Makevars (src/Makevars.win on Windows) from src/Makevars.in:
## optimization flags, header paths and the StanHeaders/RcppParallel (TBB)
## flags.  The optimization probe and the Stan/TBB blocks are the ones rxode2
## used when it compiled this code, kept identical for bitwise parity.

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

.sl <- paste(capture.output(StanHeaders:::LdFlags()), # nolint
             capture.output(RcppParallel:::RcppParallelLibs())) # nolint
# Set when the TBB link flags are stripped below; the compile-time
# STAN_THREADS/TBB defines must then be stripped too (see @SH@ handling).
.rxDisableTbb <- FALSE
if (.Platform$OS.type == "windows") {
  # rpath is not meaningful on Windows and can generate noisy linker flags.
  # The path is shQuote()d by StanHeaders, so match quoted forms first;
  # otherwise a path containing a space leaves an orphaned token behind.
  .sl <- gsub("\\s+-Wl,-rpath,('[^']*'|\"[^\"]*\"|[^[:space:]]+)", "", .sl)
  # RcppParallel 6.0.0--6.1.1 linked the static TBB provided by Rtools into
  # RcppParallel.dll and shipped no TBB library on Windows, so the
  # -L<RcppParallel/lib dir> -ltbb -ltbbmalloc emitted by StanHeaders'
  # LdFlags() pointed at nothing; TBB symbols resolved through
  # -lRcppParallel instead.  RcppParallel >= 6.2.0 builds the bundled oneTBB
  # as a shared library and ships tbb.dll/tbbmalloc.dll there again, so the
  # same flags are correct and linking them keeps STAN_THREADS on Windows.
  # Distinguish the two states by looking for the TBB library on disk: strip
  # the flags (and, via .rxDisableTbb, the STAN_THREADS/TBB defines) only
  # when RcppParallel's lib directory has no TBB to link.  When
  # TBB_LINK_LIB/TBB_LIB point at a user-supplied TBB, StanHeaders emits
  # flags for that copy on purpose, so keep them too.
  .rp_ver <- tryCatch(utils::packageVersion("RcppParallel"), error = function(e) package_version("0.0.0"))
  .tbb_env <- Sys.getenv("TBB_LINK_LIB", Sys.getenv("TBB_LIB"))
  .rp_lib <- system.file("lib", package = "RcppParallel")
  .rp_has_tbb <- nzchar(.rp_lib) &&
    length(list.files(.rp_lib, pattern = "^(lib)?tbb[0-9]*\\.(dll|dll\\.a|a)$",
                      recursive = TRUE)) > 0L
  if (.rp_ver >= "6.0.0" && !dir.exists(.tbb_env) && !.rp_has_tbb) {
    # Match ".../RcppParallel/lib" plus any arch subdir (x64, arm64, ...) in
    # shQuote()d (single-quoted), double-quoted, or unquoted form -- but not
    # ".../RcppParallel/libs" (-lRcppParallel's dir, still needed).
    .sl2 <- gsub("-L'[^']*RcppParallel[/\\\\]lib([/\\\\][^']*)?'", "", .sl)
    .sl2 <- gsub("-L\"[^\"]*RcppParallel[/\\\\]lib([/\\\\][^\"]*)?\"", "", .sl2)
    .sl2 <- gsub("-L[^-'\"[:space:]][^[:space:]]*RcppParallel[/\\\\]lib([/\\\\][^[:space:]]*)?(?=[[:space:]]|$)",
                 "", .sl2, perl = TRUE)
    if (!identical(.sl2, .sl)) {
      # The -L pointing at RcppParallel's (TBB-less) lib dir was present, so
      # the -ltbb/-ltbbmalloc flags next to it came from the same LdFlags()
      # call; drop them with it.
      .sl <- gsub("-ltbbmalloc_proxy\\b", "", .sl2)
      .sl <- gsub("-ltbbmalloc\\b", "", .sl)
      .sl <- gsub("-ltbb\\b", "", .sl)
      .sl <- gsub("\\s+", " ", trimws(.sl))
      .rxDisableTbb <- TRUE
    }
  }
}
.in <- gsub("@SL@", .sl, .in) #nolint

.badStan <- ""
.sh <- paste(capture.output(StanHeaders:::CxxFlags()), # nolint
             capture.output(RcppParallel:::CxxFlags()), # nolint
             paste0("-@ISYSTEM@'", system.file('include', package = 'StanHeaders', mustWork = TRUE), "'"),
             paste0("-@ISYSTEM@'", system.file('include', 'src', package = 'StanHeaders', mustWork = TRUE), "'"),
             .badStan)
if (.rxDisableTbb) {
  # The -ltbb/rxode2/-ltbbmalloc link flags were stripped above (RcppParallel >=
  # 6.0.0 on Windows no longer provides libtbb).  Compiling with
  # -DSTAN_THREADS / -DRCPP_PARALLEL_USE_TBB=1 would still pull stan::math's
  # ad_tape_observer (a tbb::task_scheduler_observer) into the objects,
  # leaving undefined references to tbb::detail::r1::observe at link time.
  # Drop the defines so Stan math and RcppParallel compile without TBB.
  .sh <- gsub("-DSTAN_THREADS\\b", "", .sh)
  .sh <- gsub("-DRCPP_PARALLEL_USE_TBB=1", "-DRCPP_PARALLEL_USE_TBB=0", .sh)
  .sh <- gsub("\\s+", " ", trimws(.sh))
}
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
