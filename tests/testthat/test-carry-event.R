# The linCmt() carry's -5 advance at replace (EVID 5), multiply (EVID 6) and
# reset (EVID 3) records, through _rxode2lincmt_carryEventProbe: the real
# linCmtBcarryPre(), linCmtBcarryApplyM() and linCmtBcarryAdd() on one
# synthetic subject, with each row's transition matrix M and -7 adds given,
# so no rxode2 solve and no linCmt() Jacobian is involved.

# rxode2's encoded EVID for a replace (whI 4) or multiply (whI 5) into state
# cmt0 (0-based)
.carryEvid <- function(whI, cmt0) {
  as.integer(whI * 10000L + (cmt0 + 1L) * 100L + 1L)
}

# The probe's carry after each row, as an n x m x npair array
.carryProbe <- function(evid, dose, theta, M, add, ncmt, oral0, mask = 0L,
                        linOffset = 0L, fast = FALSE) {
  .r <- .Call(
    `_rxode2lincmt_carryEventProbe`, as.integer(evid), as.double(dose), theta,
    M, add, as.integer(ncmt), as.integer(oral0), as.integer(mask),
    as.integer(linOffset), fast
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
.carryRef <- function(evid, dose, theta, M, add, mask = 0L, linOffset = 0L,
                      fast = FALSE) {
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
      if (!.skip) .s <- matrix(M[, , .i], .m, .m) %*% .s
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
  if (!is.na(thetaStep)) .theta[thetaStep:n, 1] <- 1.2
  list(
    evid = .evid, dose = .dose, theta = .theta,
    M = array(runif(m * m * n, 0.1, 0.9), c(m, m, n)),
    add = array(runif(n * m * np, -1, 1), c(n, m, np))
  )
}

# max |probe - reference| for one case
.carryErr <- function(cs, ncmt, oral0, mask = 0L, linOffset = 0L, fast = FALSE) {
  .p <- .carryProbe(cs$evid, cs$dose, cs$theta, cs$M, cs$add, ncmt, oral0,
                    mask, linOffset, fast)
  .r <- .carryRef(cs$evid, cs$dose, cs$theta, cs$M, cs$add, mask, linOffset, fast)
  max(abs(.p - .r))
}

.carryEv <- function(evid, dose) data.frame(evid = evid, dose = dose)

# The probe's carry for 6 rows of a 1-cmt IV subject with M = 0.5 and an add
# of 1 on every row, theta constant
.carryRun1 <- function(evid, dose, fast = FALSE, mask = 0L) {
  .th <- matrix(rep(c(1, 10, 0, 0, 0, 0, 0), each = 6L), 6L, 7)
  as.vector(.carryProbe(evid, dose, .th, array(0.5, c(1, 1, 6L)),
                        array(1, c(6L, 1, 1)), 1L, 0L, mask, 0L, fast))
}

test_that("a replace, multiply or reset gives the hand-computed carry", {
  .n <- 6L
  .ev <- c(101L, 0L, 0L, 0L, 0L, 0L)
  expect_equal(.carryRun1(.ev, rep(0, .n)), c(1, 1.5, 1.75, 1.875, 1.9375, 1.96875))
  # a replace at row 3 zeroes the carry before row 4's advance
  .ev[3] <- .carryEvid(4L, 0L)
  expect_equal(.carryRun1(.ev, c(100, 0, 50, 0, 0, 0)), c(1, 1.5, 1.75, 1, 1.5, 1.75))
  # a multiply by 2, on the fast path: rows 1-3 skip M; the event takes the
  # subject to the slow path at row 4
  .ev[3] <- .carryEvid(5L, 0L)
  .d <- c(100, 0, 2, 0, 0, 0)
  expect_equal(.carryRun1(.ev, .d, fast = TRUE), c(1, 2, 3, 4, 3, 2.5))
  # with f() modeled on the compartment the multiply is left out, and the
  # fast path goes on
  expect_equal(.carryRun1(.ev, .d, fast = TRUE, mask = 1L), c(1, 2, 3, 4, 5, 6))
  # a multiply by 0 clears the carry like a replace
  expect_equal(.carryRun1(.ev, c(100, 0, 0, 0, 0, 0)), c(1, 1.5, 1.75, 1, 1.5, 1.75))
  # a reset at row 3 zeroes the carry on its own row
  .ev[3] <- 3L
  expect_equal(.carryRun1(.ev, rep(0, .n)), c(1, 1.5, 1, 1.5, 1.75, 1.875))
})

test_that("replace and multiply follow the reference for every shape and compartment", {
  set.seed(42)
  # (ncmt, oral0): IV 1-cmt, oral 1-cmt, oral 2-cmt, oral 3-cmt
  for (.sh in list(c(1L, 0L), c(1L, 1L), c(2L, 1L), c(3L, 1L))) {
    .m <- sum(.sh)
    for (.np in c(1L, 3L, 8L)) {
      for (.c in seq_len(.m) - 1L) {
        .evs <- list(
          .carryEv(.carryEvid(4L, .c), 40),
          .carryEv(.carryEvid(4L, .c), 0),
          .carryEv(.carryEvid(5L, .c), 0.5),
          .carryEv(.carryEvid(5L, .c), 0),
          # several records at one time, in both orders, and with a dose
          .carryEv(c(.carryEvid(4L, .c), .carryEvid(5L, .c)), c(30, 0.5)),
          .carryEv(c(.carryEvid(5L, .c), .carryEvid(4L, .c)), c(0.5, 30)),
          .carryEv(c(101L, .carryEvid(4L, .c)), c(100, 30)),
          .carryEv(c(.carryEvid(4L, .c), 3L, .carryEvid(5L, .c)), c(30, 0, 2))
        )
        for (.k in seq_along(.evs)) {
          for (.fast in c(FALSE, TRUE)) {
            .cs <- .carryCase(.evs[[.k]], .m, .np)
            expect_lt(.carryErr(.cs, .sh[1], .sh[2], fast = .fast), 1e-12,
                      label = paste(.sh[1], .sh[2], .np, .c, .k, .fast))
          }
        }
      }
    }
  }
})

test_that("the fast path leaves at a theta change or an event, whichever is first", {
  set.seed(43)
  .ev <- .carryEv(.carryEvid(5L, 1L), 0.5)
  for (.step in c(2L, 4L, 5L, 8L, NA_integer_)) {
    .cs <- .carryCase(.ev, 2L, 3L, thetaStep = .step)
    expect_lt(.carryErr(.cs, 1L, 1L, fast = TRUE), 1e-12, label = .step)
  }
  # the event's row is the first one off the fast path: the probe differs
  # from a run that never leaves it
  .cs <- .carryCase(.ev, 2L, 1L)
  .noEv <- .cs
  .noEv$evid[4] <- 0L
  .p <- .carryProbe(.cs$evid, .cs$dose, .cs$theta, .cs$M, .cs$add, 1L, 1L, fast = TRUE)
  .p0 <- .carryProbe(.noEv$evid, .noEv$dose, .noEv$theta, .noEv$M, .noEv$add, 1L, 1L, fast = TRUE)
  expect_identical(.p[1:4, , ], .p0[1:4, , ])
  expect_false(isTRUE(all.equal(.p[5, , ], .p0[5, , ])))
})

test_that("the f() mask and the block offset select the compartment", {
  set.seed(44)
  for (.c in 0:1) {
    for (.mask in 0:3) {
      .cs <- .carryCase(.carryEv(.carryEvid(5L, .c), 0.5), 2L, 2L)
      for (.fast in c(FALSE, TRUE)) {
        expect_lt(.carryErr(.cs, 1L, 1L, mask = .mask, fast = .fast), 1e-12,
                  label = paste(.c, .mask, .fast))
      }
    }
  }
  # one ODE state before the linCmt() block: an event on it (state 0) is not
  # the block's; on state 1 it is the block's first compartment
  for (.c in 0:2) {
    .cs <- .carryCase(.carryEv(.carryEvid(4L, .c), 10), 2L, 2L)
    expect_lt(.carryErr(.cs, 1L, 1L, linOffset = 1L), 1e-12, label = .c)
  }
  .cs <- .carryCase(.carryEv(.carryEvid(4L, 0L), 10), 2L, 1L)
  .p <- .carryProbe(.cs$evid, .cs$dose, .cs$theta, .cs$M, .cs$add, 1L, 1L, linOffset = 1L)
  .noEv <- .carryProbe(c(.cs$evid[1:3], 0L, .cs$evid[-(1:4)]), .cs$dose, .cs$theta,
                       .cs$M, .cs$add, 1L, 1L, linOffset = 1L)
  expect_identical(.p, .noEv)
})

test_that("the probe restores the offsets and the fast-path switch", {
  .off <- .rxode2lincmtHostInfo()$offsets
  .fast <- .linCmtCarrySetFast(TRUE)
  .cs <- .carryCase(.carryEv(.carryEvid(4L, 0L), 10), 1L, 1L)
  .carryProbe(.cs$evid, .cs$dose, .cs$theta, .cs$M, .cs$add, 1L, 0L, fast = FALSE)
  expect_identical(.rxode2lincmtHostInfo()$offsets, .off)
  expect_true(.linCmtCarrySetFast(.fast))
  expect_error(.carryProbe(1L, c(1, 2), matrix(0, 1, 7), array(1, c(1, 1, 1)),
                           array(1, c(1, 1, 1)), 1L, 0L), "inconsistent")
  expect_error(.carryProbe(1L, 1, matrix(0, 1, 7), array(1, c(1, 1, 1)),
                           array(1, c(1, 1, 1)), 4L, 0L), "inconsistent")
})
