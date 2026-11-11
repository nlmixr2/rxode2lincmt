# The linCmt() carry's -5 advance at replace (EVID 5), multiply (EVID 6) and
# reset (EVID 3) records, through _rxode2lincmt_carryEventProbe: the real
# linCmtBcarryPre(), linCmtBcarryApplyM() and linCmtBcarryAdd() on one
# synthetic subject, with each row's transition matrix M and -7 adds given,
# so no rxode2 solve and no linCmt() Jacobian is involved.  Helpers are in
# helper-carry-event.R.

test_that("a replace, multiply or reset gives the hand-computed carry", {
  .n <- 6L
  .ev <- c(101L, 0L, 0L, 0L, 0L, 0L)
  expect_equal(
    .carryRun1(.ev, rep(0, .n)),
    c(1, 1.5, 1.75, 1.875, 1.9375, 1.96875)
  )
  # a replace at row 3 zeroes the carry before row 4's advance
  .ev[3] <- .carryEvid(4L, 0L)
  expect_equal(
    .carryRun1(.ev, c(100, 0, 50, 0, 0, 0)),
    c(1, 1.5, 1.75, 1, 1.5, 1.75)
  )
  # a multiply by 2, on the fast path: rows 1-3 skip M; the event takes the
  # subject to the slow path at row 4
  .ev[3] <- .carryEvid(5L, 0L)
  .d <- c(100, 0, 2, 0, 0, 0)
  expect_equal(.carryRun1(.ev, .d, fast = TRUE), c(1, 2, 3, 4, 3, 2.5))
  # with f() modeled on the compartment the multiply is left out, and the
  # fast path goes on
  expect_equal(.carryRun1(.ev, .d, fast = TRUE, mask = 1L), c(1, 2, 3, 4, 5, 6))
  # a multiply by 0 clears the carry like a replace
  expect_equal(
    .carryRun1(.ev, c(100, 0, 0, 0, 0, 0)),
    c(1, 1.5, 1.75, 1, 1.5, 1.75)
  )
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
            expect_lt(
              .carryErr(.cs, .sh[1], .sh[2], fast = .fast),
              1e-12,
              label = paste(.sh[1], .sh[2], .np, .c, .k, .fast)
            )
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
  .p <- .carryProbe(
    .cs$evid,
    .cs$dose,
    .cs$theta,
    .cs$M,
    .cs$add,
    1L,
    1L,
    fast = TRUE
  )
  .p0 <- .carryProbe(
    .noEv$evid,
    .noEv$dose,
    .noEv$theta,
    .noEv$M,
    .noEv$add,
    1L,
    1L,
    fast = TRUE
  )
  expect_identical(.p[1:4, , ], .p0[1:4, , ])
  expect_false(isTRUE(all.equal(.p[5, , ], .p0[5, , ])))
})

test_that("the f() mask and the block offset select the compartment", {
  set.seed(44)
  for (.c in 0:1) {
    for (.mask in 0:3) {
      .cs <- .carryCase(.carryEv(.carryEvid(5L, .c), 0.5), 2L, 2L)
      for (.fast in c(FALSE, TRUE)) {
        expect_lt(
          .carryErr(.cs, 1L, 1L, mask = .mask, fast = .fast),
          1e-12,
          label = paste(.c, .mask, .fast)
        )
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
  .p <- .carryProbe(
    .cs$evid,
    .cs$dose,
    .cs$theta,
    .cs$M,
    .cs$add,
    1L,
    1L,
    linOffset = 1L
  )
  .noEv <- .carryProbe(
    c(.cs$evid[1:3], 0L, .cs$evid[-(1:4)]),
    .cs$dose,
    .cs$theta,
    .cs$M,
    .cs$add,
    1L,
    1L,
    linOffset = 1L
  )
  expect_identical(.p, .noEv)
})

test_that("the probe restores the offsets and the fast-path switch", {
  .off <- .rxode2lincmtHostInfo()$offsets
  .fast <- .linCmtCarrySetFast(TRUE)
  .cs <- .carryCase(.carryEv(.carryEvid(4L, 0L), 10), 1L, 1L)
  .carryProbe(
    .cs$evid,
    .cs$dose,
    .cs$theta,
    .cs$M,
    .cs$add,
    1L,
    0L,
    fast = FALSE
  )
  expect_identical(.rxode2lincmtHostInfo()$offsets, .off)
  expect_true(.linCmtCarrySetFast(.fast))
  expect_error(
    .carryProbe(
      1L,
      c(1, 2),
      matrix(0, 1, 7),
      array(1, c(1, 1, 1)),
      array(1, c(1, 1, 1)),
      1L,
      0L
    ),
    "inconsistent"
  )
  expect_error(
    .carryProbe(
      1L,
      1,
      matrix(0, 1, 7),
      array(1, c(1, 1, 1)),
      array(1, c(1, 1, 1)),
      4L,
      0L
    ),
    "inconsistent"
  )
})

test_that("advCalls counts every -5 advance, a reset row's included", {
  .linCmtCarryFastStats(TRUE)
  .carryRun1(c(101L, 0L, 3L, 0L, 0L, 0L), rep(0, 6L))
  expect_equal(.linCmtCarryFastStats(TRUE)[["advCalls"]], 6)
})
