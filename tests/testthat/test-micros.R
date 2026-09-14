test_that("clearance parameterization gives the expected micro-constants", {
  expect_equal(linCmtMicros(p1 = 2, v1 = 20, ncmt = 1),
               c(v = 20, k = 0.1))
  expect_equal(linCmtMicros(p1 = 2, v1 = 20, p2 = 3, p3 = 40, ncmt = 2),
               c(v = 20, k = 0.1, k12 = 0.15, k21 = 0.075))
  expect_equal(linCmtMicros(p1 = 2, v1 = 20, p2 = 3, p3 = 40, p4 = 1, p5 = 80, ncmt = 3),
               c(v = 20, k = 0.1, k12 = 0.15, k21 = 0.075, k13 = 0.05, k31 = 0.0125))
})

test_that("rate-constant parameterization is the identity", {
  expect_equal(linCmtMicros(p1 = 0.1, v1 = 20, ncmt = 1, trans = 2),
               c(v = 20, k = 0.1))
  expect_equal(linCmtMicros(p1 = 0.1, v1 = 20, p2 = 0.15, p3 = 0.075, ncmt = 2, trans = 2),
               c(v = 20, k = 0.1, k12 = 0.15, k21 = 0.075))
  expect_equal(linCmtMicros(p1 = 0.1, v1 = 20, p2 = 0.15, p3 = 0.075, p4 = 0.05, p5 = 0.0125,
                            ncmt = 3, trans = 2),
               c(v = 20, k = 0.1, k12 = 0.15, k21 = 0.075, k13 = 0.05, k31 = 0.0125))
})

test_that("micro-constants round-trip through the solComp eigenvalues", {
  .m <- linCmtMicros(p1 = 2, v1 = 20, p2 = 3, p3 = 40, ncmt = 2)
  .s <- solComp2(k10 = .m[["k"]], k12 = .m[["k12"]], k21 = .m[["k21"]])
  .K <- .lcRateMatrix(2L, 0L, cl = 2, v = 20, q = 3, vp = 40)
  expect_equal(sort(.s$L), sort(-eigen(.K)$values))
})

test_that("unsupported parameterizations are rejected", {
  expect_error(linCmtMicros(p1 = 2, v1 = 20, ncmt = 1, trans = 3))
  expect_error(linCmtMicros(p1 = 2, v1 = 20, ncmt = 4))
})
