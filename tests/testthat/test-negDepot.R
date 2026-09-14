# A negative depot amount used to skip the 3-cmt oral depot branch, leaving
# the depot output unassigned: garbage under forward mode, a segfault under
# reverse mode (rxode2 #1275).
.callDepot <- function(alast, sensType, ka = 1.1) {
  linCmtModelDouble(0.7, 1.0, 20, 2.0, 40, 0.5, 60, ka,
                    alast, rep(0, 4), 3L, 1L, 1L, TRUE,
                    0L, 0, 0, 0, 0L, 0L, as.integer(sensType), 0.001)
}

.depot <- function(v) {
  .a <- numeric(.lcNalast(3L, 1L, TRUE))
  .a[1] <- v
  .a
}

for (.st in c(3L, 30L)) {
  test_that(sprintf("3-cmt oral kernel is linear in a negative depot (sensType %d)", .st), {
    .pos <- .callDepot(.depot(1e-6), .st)
    .neg <- .callDepot(.depot(-1e-6), .st)
    expect_equal(.neg$val, -.pos$val)
    expect_equal(.neg$J, -.pos$J)
    expect_true(all(is.finite(.neg$J)))
    .h <- 1e-6
    .fd <- (.callDepot(.depot(-1e-6), .st, ka = 1.1 + .h)$val -
              .callDepot(.depot(-1e-6), .st, ka = 1.1 - .h)$val) / (2 * .h)
    expect_equal(.neg$Jg[7], .fd, tolerance = 1e-6)
  })
}
