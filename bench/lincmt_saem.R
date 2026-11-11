# lincmt_saem.R -- the linCmtA() value path (rxode2lincmt#9): bitwise parity
# of its consumers (rxSolve() simulation, SAEM fits with tables) and SAEM
# timing on the two closed-form shapes of the issue.
#
#   R_LIBS=<lib with rxode2 + nlmixr2est> MODE=parity OUT=before.rds \
#     Rscript bench/lincmt_saem.R
#   ...rebuild...
#   R_LIBS=... MODE=parity OUT=after.rds Rscript bench/lincmt_saem.R
#   Rscript -e 'identical(readRDS("before.rds"), readRDS("after.rds"))'
#
#   R_LIBS=... MODE=time Rscript bench/lincmt_saem.R
suppressMessages({
  library(rxode2)
  library(nlmixr2est)
})
setRxThreads(1L)
mode <- Sys.getenv("MODE", "parity")
out <- Sys.getenv("OUT", "saem-parity.rds")

.mkDat <- function(nSub, obsT, doseT, cmt, rate = 0, ss = 0L) {
  .d <- do.call(
    rbind,
    lapply(seq_len(nSub), function(id) {
      rbind(
        data.frame(
          ID = id,
          TIME = doseT,
          DV = NA_real_,
          AMT = 100,
          RATE = rate,
          EVID = 1,
          SS = c(ss, rep(0L, length(doseT) - 1L)),
          II = c(if (ss) 24 else 0, rep(0, length(doseT) - 1L)),
          CMT = cmt
        ),
        data.frame(
          ID = id,
          TIME = obsT,
          DV = 0,
          AMT = 0,
          RATE = 0,
          EVID = 0,
          SS = 0L,
          II = 0,
          CMT = "central"
        )
      )
    })
  )
  .d[order(.d$ID, .d$TIME, -.d$EVID), ]
}

.p2 <- c(cl = 4, v = 30, q = 8, vp = 60)
.p3 <- c(.p2, q2 = 3, vp2 = 200)
.cases <- list(
  bolus1 = list(par = c(cl = 4, v = 30), cmt = "central"),
  inf1 = list(par = c(cl = 4, v = 30), cmt = "central", rate = 50),
  oral1 = list(par = c(ka = 1.2, cl = 4, v = 30), cmt = "depot"),
  oral1ss = list(par = c(ka = 1.2, cl = 4, v = 30), cmt = "depot", ss = 1L),
  bolus2 = list(par = .p2, cmt = "central"),
  inf2 = list(par = .p2, cmt = "central", rate = 50),
  inf2ss = list(par = .p2, cmt = "central", rate = 50, ss = 1L),
  oral2 = list(par = c(ka = 1.2, .p2), cmt = "depot"),
  bolus3 = list(par = .p3, cmt = "central"),
  oral3 = list(par = c(ka = 1.2, .p3), cmt = "depot"),
  oral3ss = list(par = c(ka = 1.2, .p3), cmt = "depot", ss = 1L),
  oral1lag = list(
    par = c(ka = 1.2, cl = 4, v = 30, lagd = 0.4),
    cmt = "depot",
    extra = "alag(depot) <- lagd"
  ),
  oral1f = list(
    par = c(ka = 1.2, cl = 4, v = 30, fd = 0.7),
    cmt = "depot",
    extra = "f(depot) <- fd"
  ),
  inf1dur = list(
    par = c(cl = 4, v = 30, dr = 1.5),
    cmt = "central",
    rate = -2,
    extra = "dur(central) <- dr"
  )
)

.etaNm <- function(p) intersect(names(p), c("ka", "cl", "v", "q", "vp"))

.simulate <- function(cs, d) {
  .p <- cs$par
  .e <- .etaNm(.p)
  .eta <- matrix(
    rnorm(length(unique(d$ID)) * length(.e), 0, 0.3),
    ncol = length(.e)
  )
  colnames(.eta) <- paste0("e.", .e)
  .m <- rxode2(paste(
    c(
      sprintf("%s <- %s", names(.p), .p),
      sprintf("%s <- %s*exp(e.%s)", .e, .e, .e),
      if (is.null(cs$extra)) "" else cs$extra,
      "cp <- linCmt()"
    ),
    collapse = "\n"
  ))
  .s <- rxSolve(
    .m,
    as.data.frame(.eta),
    d,
    returnType = "data.frame",
    addDosing = FALSE
  )
  d$DV[d$EVID == 0] <- .s$cp * (1 + rnorm(nrow(.s), 0, 0.1))
  list(data = d, sim = .s)
}

.saemModel <- function(cs) {
  .p <- cs$par
  .e <- .etaNm(.p)
  .ini <- c(
    sprintf("l%s <- log(%.6g)", names(.p), .p * 1.15),
    sprintf("eta.%s ~ 0.1", .e),
    "prop.sd <- 0.2"
  )
  .par <- vapply(
    names(.p),
    function(x) {
      if (x %in% .e) {
        sprintf("%s <- exp(l%s + eta.%s)", x, x, x)
      } else {
        sprintf("%s <- exp(l%s)", x, x)
      }
    },
    ""
  )
  eval(parse(
    text = sprintf(
      "function() {\nini({\n%s\n})\nmodel({\n%s\n%s\ncp <- linCmt()\ncp ~ prop(prop.sd)\n})\n}",
      paste(.ini, collapse = "\n"),
      paste(.par, collapse = "\n"),
      if (is.null(cs$extra)) "" else cs$extra
    )
  ))
}

.saemFit <- function(cs, d, nBurn, nEm) {
  suppressWarnings(suppressMessages(nlmixr2(
    .saemModel(cs),
    d,
    "saem",
    saemControl(
      nBurn = nBurn,
      nEm = nEm,
      nmc = 1,
      nu = c(2, 2, 2),
      print = 0,
      covMethod = "",
      calcTables = TRUE,
      logLik = TRUE,
      rxControl = rxControl(cores = 1L)
    )
  )))
}

if (mode == "parity") {
  .obsT <- c(0.25, 0.5, 1, 2, 4, 6, 8, 12, 24, 25, 26, 28, 32, 36, 48)
  .res <- list()
  for (.nm in names(.cases)) {
    .cs <- .cases[[.nm]]
    set.seed(100 + match(.nm, names(.cases)))
    .d <- .mkDat(
      12L,
      .obsT,
      c(0, 24),
      .cs$cmt,
      if (is.null(.cs$rate)) 0 else .cs$rate,
      if (is.null(.cs$ss)) 0L else .cs$ss
    )
    .s <- .simulate(.cs, .d)
    .fit <- .saemFit(.cs, .s$data, 30, 20)
    .res[[.nm]] <- list(
      sim = .s$sim,
      objf = .fit$objective,
      theta = .fit$theta,
      eta = as.matrix(.fit$eta[, -1]),
      pred = .fit$PRED,
      ipred = .fit$IPRED
    )
    cat(.nm, format(.fit$objective, digits = 15), "\n")
  }
  saveRDS(.res, out)
} else {
  .time <- list(
    "bolus-1cpt" = list(
      cs = list(par = c(cl = 4, v = 30), cmt = "central"),
      d = .mkDat(
        120L,
        c(0.25, 0.5, 1:6, 8, 10, 12, 14, 16, 20, 24, 30, 36, 42, 48),
        0,
        "central"
      )
    ),
    "oral-2cpt" = list(
      cs = list(par = c(ka = 1.2, .p2), cmt = "depot"),
      d = .mkDat(
        120L,
        sort(c(
          seq(0.5, 95.5, by = 2),
          0.25,
          0.75,
          1.25,
          1.75,
          2.25,
          2.75,
          3.25,
          3.75,
          4.25,
          4.75
        )),
        c(0, 24, 48, 72),
        "depot"
      )
    )
  )
  for (.nm in names(.time)) {
    set.seed(1)
    .cs <- .time[[.nm]]$cs
    .d <- .simulate(.cs, .time[[.nm]]$d)$data
    invisible(.saemFit(.cs, .d, 300, 100))
    .t <- vapply(
      1:3,
      function(i) system.time(.saemFit(.cs, .d, 300, 100))[["elapsed"]],
      numeric(1)
    )
    cat(.nm, "nobs", sum(.d$EVID == 0), "median", median(.t), "s (", .t, ")\n")
  }
}
