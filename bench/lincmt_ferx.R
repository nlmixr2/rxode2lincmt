# lincmt_ferx.R -- whole FOCEi fits of the bench/lincmt_focei.R models with
# nlmixr2 (linCmt()) and with ferx, which fits the same closed-form models
# (rxode2lincmt#2).
#
#   R_LIBS=~/R/lib-lincmt-dev ENGINE=nlmixr2 ROUTE=bolus NCMT=1 REPS=3 \
#     taskset -c <idle core> Rscript bench/lincmt_ferx.R
#
# ENGINE is nlmixr2 or ferx.  Both start from the same initial estimates,
# skip the covariance step and run on one thread.  nlmixr2 uses
# foceiControl() defaults otherwise.  Prints one line: engine, case, the
# minimum of REPS timed fits (after a warm-up fit) for the whole fit and,
# for nlmixr2, its optimization stage, the outer iteration count and the
# objective.
engine <- Sys.getenv("ENGINE", "nlmixr2")
Sys.setenv(ARMS = "")
source("bench/lincmt_focei.R")

caseName <- sprintf("%s-%dcpt", route, nCmt)
oneLine <- function(sec, opt, iter, objf) {
  cat(sprintf(
    "RESULT %s %s fit=%.3f optimize=%s iter=%s objf=%.3f\n",
    engine,
    caseName,
    sec,
    if (is.na(opt)) "NA" else sprintf("%.3f", opt),
    iter,
    objf
  ))
}

if (engine == "nlmixr2") {
  ctlFull <- foceiControl(
    calcTables = FALSE,
    print = 0L,
    covMethod = "",
    rxControl = rxControl(cores = 1L)
  )
  fitOnce <- function() {
    t0 <- proc.time()[["elapsed"]]
    fit <- suppressWarnings(suppressMessages(nlmixr2(
      uiLin,
      dat,
      "focei",
      ctlFull
    )))
    list(
      sec = proc.time()[["elapsed"]] - t0,
      opt = fit$time$optimize,
      iter = nrow(fit$parHistData),
      objf = fit$objective
    )
  }
} else {
  suppressMessages(library(ferx))
  tmp <- tempfile("ferx")
  dir.create(tmp)
  # ferx doses and observes by compartment number: 1 is the dose compartment
  fd <- dat
  fd$CMT <- 1L
  fd$MDV <- as.integer(fd$EVID != 0)
  fd$AMT[fd$EVID == 0] <- NA
  csv <- file.path(tmp, "data.csv")
  utils::write.csv(
    fd[, c("ID", "TIME", "DV", "EVID", "AMT", "CMT", "RATE", "MDV")],
    csv,
    row.names = FALSE,
    na = "."
  )
  up <- toupper(names(trueTheta))
  pkName <- c(
    cl = "cl",
    v = if (nCmt == 1) "v" else "v1",
    q = "q",
    vp = "v2",
    ka = "ka"
  )
  pkArgs <- paste(
    sprintf("%s=%s", pkName[names(trueTheta)], up),
    collapse = ", "
  )
  ind <- vapply(
    seq_along(up),
    function(i) {
      if (names(trueTheta)[i] %in% etaNm) {
        sprintf("  %s = TV%s * exp(ETA_%s)", up[i], up[i], up[i])
      } else {
        sprintf("  %s = TV%s", up[i], up[i])
      }
    },
    ""
  )
  mod <- c(
    "[parameters]",
    sprintf(
      "  theta TV%s(%.6g, %.6g, %.6g)",
      up,
      trueTheta * 1.2,
      trueTheta / 100,
      trueTheta * 100
    ),
    sprintf("  omega ETA_%s ~ 0.1", toupper(etaNm)),
    "  sigma PROP_ERR ~ 0.04",
    "[individual_parameters]",
    ind,
    "[structural_model]",
    sprintf(
      "  pk %s_cpt_%s(%s)",
      c("one", "two")[nCmt],
      if (oral) "oral" else "iv",
      pkArgs
    ),
    "[error_model]",
    "  DV ~ proportional(PROP_ERR)"
  )
  modFile <- file.path(tmp, "model.ferx")
  writeLines(mod, modFile)
  fitOnce <- function() {
    t0 <- proc.time()[["elapsed"]]
    fit <- ferx_fit(
      modFile,
      csv,
      method = "focei",
      covariance = FALSE,
      threads = 1L,
      verbose = FALSE
    )
    list(
      sec = proc.time()[["elapsed"]] - t0,
      opt = NA_real_,
      iter = if (is.null(fit$n_iterations)) NA else fit$n_iterations,
      objf = fit$ofv,
      fit = fit
    )
  }
}

invisible(fitOnce()) # warm-up: compiles (nlmixr2)
z <- lapply(seq_len(nRep), function(i) fitOnce())
best <- z[[which.min(vapply(z, function(r) r$sec, 0))]]
oneLine(best$sec, best$opt, best$iter, best$objf)
if (Sys.getenv("SHOW") != "" && engine == "ferx") {
  str(unclass(best$fit), max.level = 1)
}
