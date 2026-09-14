# Arguments exactly as rxode2's rxDerived() parser generates them:
# ncmt, oral, w2, trans, list(p1, v1, p2, p3, p4, p5, ...), digits
.derivedTail <- list(0, 0, 0, 0, 0.0, 0, 0, 0, 0)

.derived <- function(ncmt, trans, p, digits = 3) {
  .calcDerived(ncmt, 0, -1, trans, c(as.list(p), .derivedTail), digits)
}

test_that("rate-constant parameterizations", {
  .p1 <- .derived(1, 2, list(0.5 * 1:3, 8, 0.0, 0.0, 0.0, 0.0))
  expect_false(any(is.infinite(.p1$A)))

  expect_equal(
    .derived(1, 2, list(0.5, 8, 0.0, 0.0, 0.0, 0.0)),
    structure(list(
      vc = 8, kel = 0.5, vss = 8, cl = 4, t12alpha = 1.39,
      alpha = 0.5, A = 0.125, fracA = 1
    ), class = "data.frame", row.names = c(NA, -1L)))

  expect_equal(
    .derived(2, 2, list(0.7, 5, 0.5, 0.05, 0.0, 0.0)),
    structure(list(
      vc = 5, kel = 0.7, k12 = 0.5, k21 = 0.05, vp = 50,
      vss = 55, cl = 3.5, q = 2.5, t12alpha = 0.568, t12beta = 24.2,
      alpha = 1.22, beta = 0.0287, A = 0.196, B = 0.00358, fracA = 0.982,
      fracB = 0.0179
    ), class = "data.frame", row.names = c(NA, -1L)))

  expect_equal(
    .derived(3, 2, list(0.3, 10, 0.2, 0.02, 0.1, 0.001)),
    structure(list(
      vc = 10, kel = 0.3, k12 = 0.2, k21 = 0.02, k13 = 0.1,
      k31 = 0.001, vp = 100, vp2 = 1000, vss = 1110, cl = 3, q = 2,
      q2 = 1, t12alpha = 1.14, t12beta = 52.2, t12gamma = 931,
      alpha = 0.607, beta = 0.0133, gamma = 0.000745, A = 0.0988,
      B = 0.00111, C = 6.47e-05, fracA = 0.988, fracB = 0.0111,
      fracC = 0.000647
    ), class = "data.frame", row.names = c(NA, -1L)))
})

test_that("volume and clearance parameterizations", {
  expect_equal(
    .derived(1, 1, list(4.0, 8.0, 0.0, 0.0, 0.0, 0.0)),
    structure(list(
      vc = 8, kel = 0.5, vss = 8, cl = 4, t12alpha = 1.39,
      alpha = 0.5, A = 0.125, fracA = 1
    ), class = "data.frame", row.names = c(NA, -1L)))

  expect_equal(
    .derived(2, 1, list(3.5, 5.0, 2.5, 50, 0.0, 0.0)),
    structure(list(
      vc = 5, kel = 0.7, k12 = 0.5, k21 = 0.05, vp = 50,
      vss = 55, cl = 3.5, q = 2.5, t12alpha = 0.568, t12beta = 24.2,
      alpha = 1.22, beta = 0.0287, A = 0.196, B = 0.00358, fracA = 0.982,
      fracB = 0.0179
    ), class = "data.frame", row.names = c(NA, -1L)))

  expect_equal(
    .derived(3, 1, list(3, 10, 2, 100, 1, 1000)),
    structure(list(
      vc = 10, kel = 0.3, k12 = 0.2, k21 = 0.02, k13 = 0.1,
      k31 = 0.001, vp = 100, vp2 = 1000, vss = 1110, cl = 3, q = 2,
      q2 = 1, t12alpha = 1.14, t12beta = 52.2, t12gamma = 931,
      alpha = 0.607, beta = 0.0133, gamma = 0.000745, A = 0.0988,
      B = 0.00111, C = 6.47e-05, fracA = 0.988, fracB = 0.0111,
      fracC = 0.000647
    ), class = "data.frame", row.names = c(NA, -1L)))
})

test_that("invalid compartment counts and inputs error", {
  expect_error(.calcDerived(4, 0, -1, 1, list(1, 2), 0), "1-3")
  expect_error(.calcDerived(1, 0, -1, 1, 1, 0), "list")
})
