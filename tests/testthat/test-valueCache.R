# The linCmtA() value path reuses the micro-constants and eigen-decomposition
# while theta is unchanged bit for bit; every row must equal the uncached
# kernel exactly, across theta changes and returns to an earlier theta.
.vcPar <- function(ncmt, oral0) {
  .base <- c(4, 30, 8, 60, 3, 200, 1.2)
  .alt <- c(4.5, 28, 7, 65, 2.5, 190, 0.9)
  .rows <- list(.base, .base, .base, .alt, .alt, .base, .alt, .base)
  .p <- do.call(rbind, .rows)
  if (ncmt < 3) .p[, 5:6] <- 0
  if (ncmt < 2) .p[, 3:4] <- 0
  if (!oral0) .p[, 7] <- 0
  .p
}

test_that("value-path constant cache is bitwise identical to the kernel", {
  .dt <- c(0.5, 1, 2, 0.25, 3, 1.5, 6, 12)
  for (.ncmt in 1:3) {
    for (.oral0 in 0:1) {
      .m <- .ncmt + .oral0
      for (.rate in list(rep(0, 1 + .oral0), c(rep(0, .oral0), 25))) {
        .r <- .linCmtValueCacheCheck(
          .dt,
          .vcPar(.ncmt, .oral0),
          .ncmt,
          .oral0,
          1L,
          c(100, rep(0, .m - 1)),
          .rate
        )
        expect_identical(.r$cached, .r$direct)
        expect_true(all(is.finite(.r$cached)))
      }
    }
  }
})

test_that("value-path constant cache follows the rate-constant parameterization", {
  .p <- matrix(
    c(0.1, 20, 0.15, 0.075, 0, 0, 0,
      0.1, 20, 0.15, 0.075, 0, 0, 0,
      0.2, 20, 0.15, 0.075, 0, 0, 0),
    ncol = 7,
    byrow = TRUE
  )
  .r <- .linCmtValueCacheCheck(c(1, 2, 3), .p, 2L, 0L, 2L, c(100, 0), 0)
  expect_identical(.r$cached, .r$direct)
})

test_that("value-path constant cache rejects malformed input", {
  expect_error(.linCmtValueCacheCheck(1, matrix(1, 1, 7), 1L, 0L, 1L, c(1, 2), 0))
  expect_error(.linCmtValueCacheCheck(1, matrix(1, 1, 6), 1L, 0L, 1L, 1, 0))
})
