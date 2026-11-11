# Helpers for test-carry-event.R: synthetic subjects for
# _rxode2lincmt_carryEventProbe and the reference carry it is checked against.

# rxode2's encoded EVID for a replace (whI 4) or multiply (whI 5) into state
# cmt0 (0-based)
.carryEvid <- function(whI, cmt0) {
  as.integer(whI * 10000L + (cmt0 + 1L) * 100L + 1L)
}

# The probe's carry after each row, as an n x m x npair array
.carryProbe <- function(
  evid,
  dose,
  theta,
  M,
  add,
  ncmt,
  oral0,
  mask = 0L,
  linOffset = 0L,
  fast = FALSE
) {
  # by its registered name: lintr sees a backticked symbol as a global
  .r <- .Call(
    "_rxode2lincmt_carryEventProbe",
    as.integer(evid),
    as.double(dose),
    theta,
    M,
    add,
    as.integer(ncmt),
    as.integer(oral0),
    as.integer(mask),
    as.integer(linOffset),
    fast,
    PACKAGE = "rxode2lincmt"
  )
  array(.r, dim(add))
}

# What the carry should hold after each row.  A reset zeroes every column.
# Otherwise the previous record's replace zeroes its compartment's row, its
# multiply scales the row by the record's dose (unless the compartment's bit
# is in mask, where the row is left), and either takes the subject off the
# fast path; then M_i multiplies the carry unless the fast path skips the
# row (the first row, and every row while theta is unchanged); then the
# row's adds.
.carryRef <- function(
  evid,
  dose,
  theta,
  M,
  add,
  mask = 0L,
  linOffset = 0L,
  fast = FALSE
) {
  .n <- length(evid)
  .m <- dim(add)[2]
  .np <- dim(add)[3]
  .s <- matrix(0, .m, .np)
  .out <- array(0, dim(add))
  .varying <- 0L
  .prev <- NULL
  for (.i in seq_len(.n)) {
    if (evid[.i] == 3L) {
      .s[] <- 0
    } else {
      if (.i > 1L) {
        .e <- evid[.i - 1L]
        .whI <- (.e %/% 10000L) %% 10L
        .c <- (.e %/% 100L) %% 100L - 1L - linOffset
        if (.whI %in% 4:5 && .c >= 0L && .c < .m) {
          if (.whI == 4L) {
            .s[.c + 1L, ] <- 0
            .varying <- 2L
          } else if (bitwAnd(mask, bitwShiftL(1L, .c)) == 0L) {
            .s[.c + 1L, ] <- dose[.i - 1L] * .s[.c + 1L, ]
            .varying <- 2L
          }
        }
      }
      .skip <- FALSE
      if (fast && .varying == 0L) {
        .varying <- 1L
        .prev <- theta[.i, ]
        .skip <- TRUE
      } else if (fast && .varying == 1L) {
        if (identical(.prev, theta[.i, ])) .skip <- TRUE else .varying <- 2L
      }
      if (!.skip) .s <- matrix(M[,, .i], .m, .m) %*% .s
    }
    .s <- .s + matrix(add[.i, , ], .m, .np)
    .out[.i, , ] <- .s
  }
  .out
}

# One subject: a dose, then `ev` (data.frame(evid, dose)) after row 3, then
# observations to n rows; M and the adds are random, theta constant unless
# `thetaStep` names the row it changes at
.carryCase <- function(ev, m, np, n = 9L, thetaStep = NA_integer_) {
  .evid <- c(101L, 0L, 0L, ev$evid)
  .dose <- c(100, 0, 0, ev$dose)
  .evid <- c(.evid, rep(0L, n - length(.evid)))
  .dose <- c(.dose, rep(0, n - length(.dose)))
  .theta <- matrix(rep(c(1, 10, 0.5, 0, 0, 0, 1.1), each = n), n, 7)
  if (!is.na(thetaStep)) {
    .theta[thetaStep:n, 1] <- 1.2
  }
  list(
    evid = .evid,
    dose = .dose,
    theta = .theta,
    M = array(runif(m * m * n, 0.1, 0.9), c(m, m, n)),
    add = array(runif(n * m * np, -1, 1), c(n, m, np))
  )
}

# max |probe - reference| for one case
.carryErr <- function(
  cs,
  ncmt,
  oral0,
  mask = 0L,
  linOffset = 0L,
  fast = FALSE
) {
  .p <- .carryProbe(
    cs$evid,
    cs$dose,
    cs$theta,
    cs$M,
    cs$add,
    ncmt,
    oral0,
    mask,
    linOffset,
    fast
  )
  .r <- .carryRef(
    cs$evid,
    cs$dose,
    cs$theta,
    cs$M,
    cs$add,
    mask,
    linOffset,
    fast
  )
  max(abs(.p - .r))
}

.carryEv <- function(evid, dose) data.frame(evid = evid, dose = dose)

# The probe's carry for 6 rows of a 1-cmt IV subject with M = 0.5 and an add
# of 1 on every row, theta constant
.carryRun1 <- function(evid, dose, fast = FALSE, mask = 0L) {
  .th <- matrix(rep(c(1, 10, 0, 0, 0, 0, 0), each = 6L), 6L, 7)
  as.vector(.carryProbe(
    evid,
    dose,
    .th,
    array(0.5, c(1, 1, 6L)),
    array(1, c(6L, 1, 1)),
    1L,
    0L,
    mask,
    0L,
    fast
  ))
}
