# Initial amounts (op->inits) in the per-origin decomposition (which1 = -9
# dose time, -10 bioavailability): they are not a dose, so no origin's read
# may carry any part of them, at any record.

.oiW2 <- function(q) as.integer(q * 8L + 7L)

.oiInits <- function(m) c(30, 50, 10, 5)[seq_len(m)]

# a bolus into state 0 at 0, a bolus into the last dosable state at 12, with
# observations at both dose times
.oiEv <- function(oral0) {
  .ev <- data.frame(
    time = c(0, 0, 0.5, 2, 6, 12, 12, 12.5, 18, 24),
    cmt = c(0L, -1L, -1L, -1L, -1L, oral0, -1L, -1L, -1L, -1L),
    amt = c(100, 0, 0, 0, 0, 40, 0, 0, 0, 0),
    rate = 0
  )
  .ev
}

# central finite difference of the concentration in a scale or a shift of
# the doses into state `cmt`, the initial amounts held fixed
.oiFd <- function(ev, p, ncmt, oral0, cmt, inits, scale = FALSE, h = 1e-6) {
  .move <- function(s) {
    .e <- ev
    .d <- .e$cmt == cmt
    if (scale) {
      .e$amt[.d] <- .e$amt[.d] * (1 + s)
    } else {
      .e$time[.d] <- .e$time[.d] + s
    }
    .hsRun(.e, p, ncmt, oral0, inits = inits)$lhs
  }
  (.move(h) - .move(-h)) / (2 * h)
}

.oiRel <- function(a, b) max(abs(a - b)) / (max(abs(b)) + 1e-8)

test_that("initial amounts reach the value and the parameter gradient", {
  for (.oral0 in 0:1) {
    for (.ncmt in 1:3) {
      .m <- .ncmt + .oral0
      .ev <- .oiEv(.oral0)
      .p <- .hsPar(.ncmt, .oral0)
      .ini <- .oiInits(.m)
      .ref <- .hsRef(.ev, .p, .ncmt, .oral0, inits = .ini)
      .a <- .hsRun(.ev, .p, .ncmt, .oral0, inits = .ini)
      expect_equal(.a$lhs, .ref$lhs, tolerance = 1e-10)
      .b <- .hsRun(.ev, .p, .ncmt, .oral0,
        useB = TRUE, calls = .hsJgCalls(.ncmt, .oral0),
        inits = .ini
      )
      expect_equal(.b$lhs, .ref$lhs, tolerance = 1e-10)
      .idx <- .hsIdx(.ncmt, .oral0)
      .fd <- vapply(
        .idx,
        function(.j) {
          .h <- 1e-6 * abs(.p[.j])
          .up <- .p
          .up[.j] <- .up[.j] + .h
          .dn <- .p
          .dn[.j] <- .dn[.j] - .h
          (.hsRun(.ev, .up, .ncmt, .oral0, inits = .ini)$lhs -
            .hsRun(.ev, .dn, .ncmt, .oral0, inits = .ini)$lhs) / (2 * .h)
        },
        numeric(nrow(.ev))
      )
      expect_lt(.oiRel(.b$calls, .fd), 1e-5)
    }
  }
})

test_that("the per-origin reads never book the initial amounts as a dose", {
  for (.oral0 in 0:1) {
    for (.ncmt in 1:3) {
      .m <- .ncmt + .oral0
      .ev <- .oiEv(.oral0)
      .p <- .hsPar(.ncmt, .oral0)
      .ini <- .oiInits(.m)
      .q <- seq_len(.m) - 1L
      .calls <- rbind(cbind(-10L, .oiW2(.q)), cbind(-9L, .oiW2(.q)))
      .b <- .hsRun(.ev, .p, .ncmt, .oral0,
        useB = TRUE, calls = .calls,
        originMask = bitwShiftL(1L, .m) - 1L, inits = .ini
      )
      expect_false(anyNA(.b$calls))
      for (.k in seq_along(.q)) {
        .bio <- .b$calls[, .k]
        .dt <- .b$calls[, .m + .k]
        if (any(.ev$cmt == .q[.k])) {
          expect_lt(.oiRel(.bio, .oiFd(.ev, .p, .ncmt, .oral0, .q[.k], .ini, scale = TRUE)), 1e-6)
          .ok <- .ev$time > 0
          expect_lt(.oiRel(.dt[.ok], .oiFd(.ev, .p, .ncmt, .oral0, .q[.k], .ini)[.ok]), 1e-6)
        } else {
          # undosed: nothing came through this origin
          expect_equal(.bio, rep(0, nrow(.ev)))
          expect_equal(.dt, rep(0, nrow(.ev)))
        }
      }
    }
  }
})

test_that("an initial amount in a compartment dosed only by it reads 0 (rxode2lincmt#26)", {
  # the issue's regimen: a depot dose, central starting at 50
  .ev <- data.frame(
    time = c(0, 1, 2, 4, 8),
    cmt = c(0L, -1L, -1L, -1L, -1L),
    amt = c(100, 0, 0, 0, 0),
    rate = 0
  )
  .p <- c(4, 20, 0, 0, 0, 0, 1.1)
  .b <- .hsRun(.ev, .p, 1L, 1L,
    useB = TRUE, calls = cbind(-10L, .oiW2(1L)),
    originMask = 3L, inits = c(0, 50)
  )
  expect_equal(.b$calls[, 1], rep(0, 5))
})

test_that("a steady state replaces the initial amounts", {
  .ev <- data.frame(
    time = c(0, 2, 6, 12),
    cmt = c(0L, -1L, -1L, -1L),
    amt = c(100, 0, 0, 0),
    rate = 0
  )
  .ss <- data.frame(type = c(3L, 0L, 0L, 0L), tau = c(12, 0, 0, 0), var = c(100, 0, 0, 0), cmt = 0L)
  .p <- .hsPar(2L, 1L)
  .b <- .hsRun(.ev, .p, 2L, 1L,
    useB = TRUE, calls = cbind(-10L, .oiW2(0:1)),
    originMask = 3L, ss = .ss, inits = c(30, 50, 10)
  )
  .b0 <- .hsRun(.ev, .p, 2L, 1L,
    useB = TRUE, calls = cbind(-10L, .oiW2(0:1)),
    originMask = 3L, ss = .ss
  )
  expect_equal(.b$calls, .b0$calls)
})

test_that("linCmtHostSim refuses initial amounts of the wrong length", {
  .ev <- .oiEv(1L)
  expect_error(.hsRun(.ev, .hsPar(1L, 1L), 1L, 1L, inits = 1), "inconsistent inputs")
})
