# Drives .linCmtHostSim(): one synthetic subject solved through the real
# linCmtA()/linCmtB() on stand-in solver structs (no rxode2).
#
# ev: data.frame(time, cmt, amt, rate) -- cmt is the linCmt state (0 = depot
# when oral, else central), -1 for an observation; theta: one row of
# (p1, v1, p2, p3, p4, p5, ka) per record, or one vector for every record.
.hsTheta <- function(theta, n) {
  if (is.matrix(theta)) {
    return(theta)
  }
  matrix(rep(theta, each = n), n, 7)
}

.hsRun <- function(
  ev,
  theta,
  ncmt,
  oral0,
  useB = FALSE,
  sensType = 3L,
  ndiff = 127L,
  sensPhi = -1L,
  calls = matrix(integer(0), 0, 2),
  linH = rep(1e-4, 7),
  trans = 1L,
  ss = NULL,
  lagMask = 0L,
  originMask = 0L,
  hPar = -1L,
  hStep = 0,
  forwardMax = 2L,
  inits = numeric(0)
) {
  .n <- nrow(ev)
  if (is.null(ss)) {
    ss <- data.frame(type = rep(0L, .n), tau = 0, var = 0, cmt = 0L)
  }
  .linCmtHostSim(
    as.double(ev$time),
    as.integer(ev$cmt),
    as.double(ev$amt),
    as.double(ev$rate),
    .hsTheta(theta, .n),
    as.integer(ncmt),
    as.integer(oral0),
    as.integer(trans),
    useB,
    as.integer(sensType),
    as.integer(ndiff),
    as.integer(sensPhi),
    matrix(as.integer(calls), ncol = 2),
    as.double(linH),
    as.integer(ss$type),
    as.double(ss$tau),
    as.double(ss$var),
    as.integer(ss$cmt),
    as.integer(lagMask),
    as.integer(originMask),
    as.integer(hPar),
    as.double(hStep),
    as.integer(forwardMax),
    as.double(inits)
  )
}

# Base-R reference: the concentration at every record after advancing to it
# (`val`, NA for a record at the previous record's time) and after its dose
# (`lhs`, what the solve buffer holds), with record i's interval solved under
# record i's theta (as the kernel does), starting from the amounts `inits`.
.hsRef <- function(ev, theta, ncmt, oral0, inits = numeric(0)) {
  .n <- nrow(ev)
  .th <- .hsTheta(theta, .n)
  .m <- ncmt + oral0
  .a <- if (length(inits)) as.double(inits) else numeric(.m)
  .r <- numeric(.m)
  .val <- rep(NA_real_, .n)
  .lhs <- rep(NA_real_, .n)
  for (.i in seq_len(.n)) {
    if (.i > 1 && ev$time[.i] != ev$time[.i - 1]) {
      .p <- .th[.i, ]
      .km <- .lcRateMatrix(ncmt, oral0, .p[1], .p[2], .p[3], .p[4], .p[5], .p[6], .p[7])
      .a <- .lcAmounts(.km, ev$time[.i] - ev$time[.i - 1], .a, .r)
      .val[.i] <- .a[oral0 + 1L] / .p[2]
    }
    if (ev$cmt[.i] >= 0) {
      if (ev$rate[.i] != 0) {
        .r[ev$cmt[.i] + 1L] <- .r[ev$cmt[.i] + 1L] + ev$rate[.i]
      } else {
        .a[ev$cmt[.i] + 1L] <- .a[ev$cmt[.i] + 1L] + ev$amt[.i]
      }
    }
    .lhs[.i] <- .a[oral0 + 1L] / .th[.i, 2]
  }
  list(val = .val, lhs = .lhs)
}

# A regimen: a bolus (or a 2 h infusion) at 0 and 12, observations between
.hsEv <- function(oral0, infusion = FALSE, times = c(0.5, 1, 2, 4, 6, 8, 12, 13, 14, 16, 20, 24)) {
  .dose <- function(t) {
    if (infusion) {
      data.frame(time = c(t, t + 2), cmt = oral0, amt = 0, rate = c(50, -50))
    } else {
      data.frame(time = t, cmt = 0L, amt = 100, rate = 0)
    }
  }
  .ev <- rbind(
    .dose(0),
    .dose(12),
    data.frame(time = times, cmt = -1L, amt = 0, rate = 0)
  )
  .ev <- .ev[order(.ev$time, -.ev$cmt), ]
  rownames(.ev) <- NULL
  .ev
}

.hsPar <- function(ncmt, oral0) {
  .p <- c(2, 20, 3, 40, 1, 80, 1.1)
  if (ncmt < 3) {
    .p[5:6] <- 0
  }
  if (ncmt < 2) {
    .p[3:4] <- 0
  }
  if (!oral0) {
    .p[7] <- 0
  }
  .p
}

# columns of theta the kernel differentiates, in its order
.hsIdx <- function(ncmt, oral0) c(seq_len(2L * ncmt), if (oral0) 7L)

# Jg reads (which1 = -2, which2 = j) for every parameter
.hsJgCalls <- function(ncmt, oral0) {
  cbind(-2L, seq_along(.hsIdx(ncmt, oral0)) - 1L)
}

# central finite differences of the linCmtA() concentration in each
# parameter (a theta matrix has the whole column perturbed)
.hsFd <- function(ev, theta, ncmt, oral0, rel = 1e-6, ss = NULL) {
  .idx <- .hsIdx(ncmt, oral0)
  .th <- .hsTheta(theta, nrow(ev))
  vapply(
    .idx,
    function(.j) {
      .h <- rel * max(abs(.th[, .j]))
      .up <- .th
      .up[, .j] <- .up[, .j] + .h
      .dn <- .th
      .dn[, .j] <- .dn[, .j] - .h
      (.hsRun(ev, .up, ncmt, oral0, ss = ss)$lhs - .hsRun(ev, .dn, ncmt, oral0, ss = ss)$lhs) / (2 * .h)
    },
    numeric(nrow(ev))
  )
}
