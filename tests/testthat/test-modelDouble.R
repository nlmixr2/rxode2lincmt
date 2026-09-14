.lcPar <- c(cl = 2, v = 20, q = 3, vp = 40, q2 = 1, vp2 = 80, ka = 1.1)

.lcCall <- function(dt, par, ncmt, oral0, alast, rate, deriv, sensType = 3L) {
  linCmtModelDouble(dt, par[["cl"]], par[["v"]], par[["q"]], par[["vp"]],
                    par[["q2"]], par[["vp2"]], par[["ka"]],
                    as.double(alast), as.double(rate), as.integer(ncmt),
                    as.integer(oral0), 1L, deriv, 0L, 0, 0, 0, 0L, 0L,
                    as.integer(sensType), 0.001)
}

.lcK <- function(par, ncmt, oral0) {
  .lcRateMatrix(ncmt, oral0, par[["cl"]], par[["v"]], par[["q"]], par[["vp"]],
                par[["q2"]], par[["vp2"]], par[["ka"]])
}

for (.ncmt in 1:3) {
  for (.oral0 in 0:1) {
    test_that(sprintf("bolus concentration matches closed form (ncmt %d, oral %d)", .ncmt, .oral0), {
      .nstate <- .ncmt + .oral0
      .a0 <- c(100, numeric(.nstate - 1L))
      .K <- .lcK(.lcPar, .ncmt, .oral0)
      for (.dt in c(0.1, 1, 5)) {
        .r <- .lcCall(.dt, .lcPar, .ncmt, .oral0, .a0, numeric(.nstate), FALSE)
        .amt <- .lcAmounts(.K, .dt, .a0)
        expect_equal(.r$val, .amt[.oral0 + 1L] / .lcPar[["v"]], tolerance = 1e-8)
      }
    })
  }

  test_that(sprintf("infusion concentration matches closed form (ncmt %d)", .ncmt), {
    .rate <- c(5, numeric(.ncmt - 1L))
    .a0 <- c(10, numeric(.ncmt - 1L))
    .K <- .lcK(.lcPar, .ncmt, 0L)
    for (.dt in c(0.5, 2)) {
      .r <- .lcCall(.dt, .lcPar, .ncmt, 0L, .a0, .rate, FALSE)
      .amt <- .lcAmounts(.K, .dt, .a0, .rate)
      expect_equal(.r$val, .amt[1] / .lcPar[["v"]], tolerance = 1e-8)
    }
  })
}

for (.ncmt in 1:3) {
  for (.oral0 in 0:1) {
    test_that(sprintf("concentration gradient matches finite differences (ncmt %d, oral %d)",
                      .ncmt, .oral0), {
      .alast <- c(100, numeric(.lcNalast(.ncmt, .oral0, TRUE) - 1L))
      .rate <- numeric(.ncmt + .oral0)
      .r <- .lcCall(1.0, .lcPar, .ncmt, .oral0, .alast, .rate, TRUE)
      .idx <- c(seq_len(2L * .ncmt), if (.oral0 == 1L) 7L)
      expect_length(.r$Jg, length(.idx))
      for (.j in seq_along(.idx)) {
        .h <- 1e-6 * .lcPar[[.idx[.j]]]
        .up <- .lcPar
        .up[.idx[.j]] <- .up[.idx[.j]] + .h
        .dn <- .lcPar
        .dn[.idx[.j]] <- .dn[.idx[.j]] - .h
        .fd <- (.lcCall(1.0, .up, .ncmt, .oral0, .alast, .rate, TRUE)$val -
                  .lcCall(1.0, .dn, .ncmt, .oral0, .alast, .rate, TRUE)$val) / (2 * .h)
        expect_equal(.r$Jg[.j], .fd, tolerance = 1e-5)
      }
    })
  }
}

test_that("a wrong carried-state length is an error", {
  expect_error(.lcCall(1.0, .lcPar, 2L, 0L, c(100, 0, 0), numeric(2), FALSE), "Alast0 size")
})
