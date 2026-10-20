# lincmt_parity.R -- record linCmt() solve and FOCEi results so a change to
# the per-row path can be checked for bitwise parity (rxode2lincmt#2).
#
#   R_LIBS=<lib with rxode2 + nlmixr2est> OUT=before.rds Rscript bench/lincmt_parity.R
#   ...rebuild...
#   R_LIBS=... OUT=after.rds Rscript bench/lincmt_parity.R
#   Rscript -e 'a <- readRDS("before.rds"); b <- readRDS("after.rds");
#               print(identical(a, b))'
#
# Covers 1-3 compartments, bolus/infusion/oral, steady state, modeled lag,
# bioavailability and duration (the dose-time and carry sentinels) and a
# FOCEi fit per shape.
suppressMessages({
  library(rxode2)
  library(nlmixr2est)
})
setRxThreads(1L)
out <- Sys.getenv("OUT", "parity.rds")

set.seed(7)
nSub <- 12L
obsT <- c(0.25, 0.5, 1, 2, 4, 6, 8, 12, 24, 25, 26, 28, 32, 36, 48)
mkDat <- function(cmt, rate = 0, ss = 0L) {
  d <- do.call(
    rbind,
    lapply(seq_len(nSub), function(id) {
      rbind(
        data.frame(
          ID = id,
          TIME = c(0, 24),
          DV = NA_real_,
          AMT = 100,
          RATE = rate,
          EVID = 1,
          SS = c(ss, 0L),
          II = c(if (ss) 24 else 0, 0),
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
  d[order(d$ID, d$TIME, -d$EVID), ]
}

cases <- list(
  bolus1 = list(par = c(cl = 4, v = 30), cmt = "central", rate = 0),
  inf1 = list(par = c(cl = 4, v = 30), cmt = "central", rate = 50),
  oral1 = list(par = c(ka = 1.2, cl = 4, v = 30), cmt = "depot", rate = 0),
  oral1ss = list(
    par = c(ka = 1.2, cl = 4, v = 30),
    cmt = "depot",
    rate = 0,
    ss = 1L
  ),
  bolus2 = list(
    par = c(cl = 4, v = 30, q = 8, vp = 60),
    cmt = "central",
    rate = 0
  ),
  inf2 = list(
    par = c(cl = 4, v = 30, q = 8, vp = 60),
    cmt = "central",
    rate = 50
  ),
  oral2 = list(
    par = c(ka = 1.2, cl = 4, v = 30, q = 8, vp = 60),
    cmt = "depot",
    rate = 0
  ),
  oral3 = list(
    par = c(ka = 1.2, cl = 4, v = 30, q = 8, vp = 60, q2 = 3, vp2 = 200),
    cmt = "depot",
    rate = 0
  ),
  oral1lag = list(
    par = c(ka = 1.2, cl = 4, v = 30, lagd = 0.4),
    cmt = "depot",
    rate = 0,
    extra = "alag(depot) <- lagd"
  ),
  oral1f = list(
    par = c(ka = 1.2, cl = 4, v = 30, fd = 0.7),
    cmt = "depot",
    rate = 0,
    extra = "f(depot) <- fd"
  ),
  inf1dur = list(
    par = c(cl = 4, v = 30, dr = 1.5),
    cmt = "central",
    rate = -2,
    extra = "dur(central) <- dr"
  )
)

simulate <- function(cs) {
  d <- mkDat(cs$cmt, cs$rate, if (is.null(cs$ss)) 0L else cs$ss)
  eta <- matrix(rnorm(nSub * 2, 0, 0.3), nSub)
  p <- cs$par
  ex <- if (is.null(cs$extra)) "" else cs$extra
  m <- rxode2(paste(
    c(
      sprintf("%s <- %s", names(p), p),
      "cl <- cl*exp(e1)",
      "v <- v*exp(e2)",
      ex,
      "cp <- linCmt()"
    ),
    collapse = "\n"
  ))
  s <- rxSolve(
    m,
    data.frame(e1 = eta[, 1], e2 = eta[, 2]),
    d,
    returnType = "data.frame",
    addDosing = FALSE
  )
  d$DV[d$EVID == 0] <- s$cp * (1 + rnorm(nrow(s), 0, 0.1))
  d
}

fitCase <- function(nm, cs, d) {
  p <- cs$par
  eNm <- c("cl", "v")
  ini <- c(
    sprintf("l%s <- log(%.6g)", names(p), p * 1.15),
    sprintf("eta.%s ~ 0.1", eNm),
    "prop.sd <- 0.2"
  )
  par <- vapply(
    names(p),
    function(x) {
      if (x %in% eNm) {
        sprintf("%s <- exp(l%s + eta.%s)", x, x, x)
      } else {
        sprintf("%s <- exp(l%s)", x, x)
      }
    },
    ""
  )
  ex <- if (is.null(cs$extra)) "" else cs$extra
  f <- eval(parse(
    text = sprintf(
      "function() {\nini({\n%s\n})\nmodel({\n%s\n%s\ncp <- linCmt()\ncp ~ prop(prop.sd)\n})\n}",
      paste(ini, collapse = "\n"),
      paste(par, collapse = "\n"),
      ex
    )
  ))
  fit <- suppressWarnings(suppressMessages(nlmixr2(
    f,
    d,
    "focei",
    foceiControl(
      print = 0L,
      maxOuterIterations = 8L,
      covMethod = "r,s",
      rxControl = rxControl(cores = 1L)
    )
  )))
  list(
    objf = fit$objective,
    theta = fit$theta,
    eta = as.matrix(fit$eta[, -1]),
    pred = fit$PRED,
    ipred = fit$IPRED,
    cov = fit$cov
  )
}

res <- list()
for (nm in names(cases)) {
  set.seed(100 + match(nm, names(cases)))
  d <- simulate(cases[[nm]])
  res[[nm]] <- list(data = d, fit = fitCase(nm, cases[[nm]], d))
  cat(nm, format(res[[nm]]$fit$objf, digits = 15), "\n")
}
saveRDS(res, out)
