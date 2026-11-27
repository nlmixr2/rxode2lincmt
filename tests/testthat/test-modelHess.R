# Prototype checks for linCmtModelHess() (rxode2lincmt#17): exact Hessians
# of linCmt() amounts/concentrations via nested forward-mode AD with a
# quadratic carry-forward of the dose history.

# Full-theta differentiation mask: ka 1, p1 2, v1 4, p2 8, p3 16, p4 32, p5 64
.hessMask <- function(ncmt, oral0) {
  as.integer(c(6L, 30L, 126L)[ncmt] + oral0)
}

.hessTheta <- function(theta, ncmt, oral0) {
  # theta in (p1, v1, p2, p3, p4, p5, ka) order of the model
  .t <- c(theta, rep(0, 7))
  list(
    p1 = .t[1],
    v1 = .t[2],
    p2 = if (ncmt >= 2) .t[3] else 0,
    p3 = if (ncmt >= 2) .t[4] else 0,
    p4 = if (ncmt >= 3) .t[5] else 0,
    p5 = if (ncmt >= 3) .t[6] else 0,
    ka = if (oral0) theta[2 * ncmt + 1] else 0
  )
}

# A dosing record list: each step is list(dt, dose (amount added to the
# dosed compartment at the START of the step), rate (per compartment))
.hessRegimen <- function(oral0, ncmt, infusion = FALSE) {
  .m <- ncmt + oral0
  .r0 <- rep(0, .m)
  .rInf <- .r0
  .rInf[oral0 + 1] <- 50
  list(
    list(dt = 1, dose = if (infusion) 0 else 100, rate = if (infusion) .rInf else .r0),
    list(dt = 3, dose = 0, rate = .r0),
    list(dt = 8, dose = 0, rate = .r0),
    list(dt = 2, dose = 100, rate = .r0),
    list(dt = 10, dose = 0, rate = .r0),
    list(dt = 5, dose = 100, rate = .r0),
    list(dt = 7, dose = 0, rate = .r0)
  )
}

# Chain linCmtModelHess(); returns per-step concentration, gradient, Hessian
.hessChain <- function(theta, ncmt, oral0, reg, quadCarry = TRUE) {
  .p <- .hessTheta(theta, ncmt, oral0)
  .m <- ncmt + oral0
  .n <- 2 * ncmt + oral0
  .nA <- .m + ncmt * .n + oral0
  .alast <- rep(0, .nA)
  .hCarry <- rep(0, .m * .n * .n)
  .c <- oral0 + 1
  .eV <- rep(0, .n)
  .eV[2] <- 1
  lapply(reg, function(s) {
    .alast[1] <<- .alast[1] + s$dose
    .r <- linCmtModelHess(
      s$dt,
      .p$p1,
      .p$v1,
      .p$p2,
      .p$p3,
      .p$p4,
      .p$p5,
      .p$ka,
      .alast,
      .hCarry,
      s$rate,
      ncmt,
      oral0,
      1L,
      quadCarry = quadCarry
    )
    .alast <<- .r$Alast
    .hCarry <<- as.vector(.r$H)
    # concentration = central amount / v1 (trans = 1)
    .amt <- .r$fx[.c]
    .jac <- .r$J[.c, ]
    .hAmt <- .r$H[,, .c]
    .vol <- .p$v1
    list(
      val = .amt / .vol,
      grad = .jac / .vol - .amt / .vol^2 * .eV,
      hess = .hAmt / .vol - (outer(.jac, .eV) + outer(.eV, .jac)) / .vol^2 + 2 * .amt / .vol^3 * outer(.eV, .eV),
      Hc = .r$Hc,
      Jg = .r$Jg,
      cval = .r$val,
      fx = .r$fx,
      J = .r$J
    )
  })
}

# Reference: chain linCmtModelDouble(deriv = TRUE) with forward AD
.hessChainDouble <- function(theta, ncmt, oral0, reg) {
  .p <- .hessTheta(theta, ncmt, oral0)
  .m <- ncmt + oral0
  .n <- 2 * ncmt + oral0
  .alast <- rep(0, .m + ncmt * .n + oral0)
  lapply(reg, function(s) {
    .alast[1] <<- .alast[1] + s$dose
    .r <- linCmtModelDouble(
      s$dt,
      .p$p1,
      .p$v1,
      .p$p2,
      .p$p3,
      .p$p4,
      .p$p5,
      .p$ka,
      .alast,
      s$rate,
      ncmt,
      oral0,
      1L,
      TRUE,
      0L,
      0,
      0,
      0,
      0L,
      .hessMask(ncmt, oral0),
      3L
    )
    .alast <<- .r$Alast
    .r
  })
}

# Central differences of the exact AD gradient -> Hessian per step
.hessFd <- function(theta, ncmt, oral0, reg, rel = 1e-5) {
  .n <- length(theta)
  .ns <- length(reg)
  .out <- replicate(.ns, matrix(0, .n, .n), simplify = FALSE)
  for (k in seq_len(.n)) {
    .h <- rel * abs(theta[k])
    .tp <- theta
    .tp[k] <- .tp[k] + .h
    .tm <- theta
    .tm[k] <- .tm[k] - .h
    .gp <- .hessChainDouble(.tp, ncmt, oral0, reg)
    .gm <- .hessChainDouble(.tm, ncmt, oral0, reg)
    for (s in seq_len(.ns)) {
      .out[[s]][, k] <- (.gp[[s]]$Jg - .gm[[s]]$Jg) / (2 * .h)
    }
  }
  .out
}

.hessCases <- list(
  list(name = "1cmt iv", ncmt = 1L, oral0 = 0L, theta = c(2, 20)),
  list(name = "1cmt oral", ncmt = 1L, oral0 = 1L, theta = c(2, 20, 0.8)),
  list(name = "2cmt iv", ncmt = 2L, oral0 = 0L, theta = c(2, 20, 4, 40)),
  list(name = "2cmt oral", ncmt = 2L, oral0 = 1L, theta = c(2, 20, 4, 40, 0.8)),
  list(name = "3cmt iv", ncmt = 3L, oral0 = 0L, theta = c(2, 20, 4, 40, 1, 60)),
  list(name = "3cmt oral", ncmt = 3L, oral0 = 1L, theta = c(2, 20, 4, 40, 1, 60, 0.8))
)

.relErr <- function(a, b) max(abs(a - b)) / max(abs(b))

for (.cs in .hessCases) {
  for (.inf in c(FALSE, TRUE)) {
    if (.inf && .cs$oral0 == 1L) {
      next
    }
    .lab <- paste0(.cs$name, if (.inf) " infusion" else " bolus")
    test_that(paste("linCmtModelHess first order matches linCmtModelDouble:", .lab), {
      .reg <- .hessRegimen(.cs$oral0, .cs$ncmt, .inf)
      .h <- .hessChain(.cs$theta, .cs$ncmt, .cs$oral0, .reg)
      .d <- .hessChainDouble(.cs$theta, .cs$ncmt, .cs$oral0, .reg)
      for (s in seq_along(.reg)) {
        expect_equal(.h[[s]]$val, .d[[s]]$val, tolerance = 1e-12)
        expect_equal(as.vector(.h[[s]]$grad), as.vector(.d[[s]]$Jg), tolerance = 1e-10)
      }
    })
    test_that(paste("linCmtModelHess Hessian matches FD of exact gradient:", .lab), {
      .reg <- .hessRegimen(.cs$oral0, .cs$ncmt, .inf)
      .h <- .hessChain(.cs$theta, .cs$ncmt, .cs$oral0, .reg)
      .fd <- .hessFd(.cs$theta, .cs$ncmt, .cs$oral0, .reg)
      for (s in seq_along(.reg)) {
        expect_lt(.relErr(.h[[s]]$hess, .fd[[s]]), 1e-6)
        expect_equal(.h[[s]]$hess, t(.h[[s]]$hess))
        # the kernel's own concentration Hessian (nested AD through getVcT)
        expect_equal(unname(.h[[s]]$Hc), unname(.h[[s]]$hess), tolerance = 1e-10)
        expect_equal(.h[[s]]$cval, .h[[s]]$val, tolerance = 1e-12)
        expect_equal(as.vector(.h[[s]]$Jg), as.vector(.h[[s]]$grad), tolerance = 1e-10)
      }
    })
  }
}

test_that("the linear carry-forward is exact for one dose and wrong after a second dose", {
  .cs <- .hessCases[[4]] # 2cmt oral
  .reg <- .hessRegimen(.cs$oral0, .cs$ncmt)
  .q <- .hessChain(.cs$theta, .cs$ncmt, .cs$oral0, .reg, quadCarry = TRUE)
  .l <- .hessChain(.cs$theta, .cs$ncmt, .cs$oral0, .reg, quadCarry = FALSE)
  .fd <- .hessFd(.cs$theta, .cs$ncmt, .cs$oral0, .reg)
  # step 1 starts from a parameter-free state: both carries agree
  expect_equal(.l[[1]]$hess, .q[[1]]$hess)
  # later steps: gradient still right, Hessian wrong with the linear carry
  for (s in 2:length(.reg)) {
    expect_equal(.l[[s]]$grad, .q[[s]]$grad, tolerance = 1e-12)
    expect_gt(.relErr(.l[[s]]$hess, .fd[[s]]), 1e-3)
  }
})
