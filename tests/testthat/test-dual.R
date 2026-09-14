# sensType 32 (all directions in one forward-mode pass) against 3 (fvar).
# The value is one shared primal and must hold to the bit; the Jacobians are
# different template instantiations, which a compiler may FMA-contract
# differently, so they are held to round-off.
.relMax <- function(x, y) {
  x <- as.numeric(x)
  y <- as.numeric(y)
  if (!identical(length(x), length(y))) return(Inf)
  .d <- abs(x - y)
  .sc <- pmax(abs(x), abs(y))
  max(ifelse(.sc > 0, .d / .sc, .d))
}

test_that("linCmtModelDouble serves sensType 32 and agrees with 3 to round-off", {
  for (.cfg in list(c(1L, 1L), c(2L, 1L), c(3L, 1L))) {
    .ncmt <- .cfg[1]
    .oral0 <- .cfg[2]
    .nstate <- .ncmt + .oral0
    .alast <- c(100, numeric(.lcNalast(.ncmt, .oral0, TRUE) - 1L))
    .call1 <- function(sensType) {
      linCmtModelDouble(1.0, 1.0, 20, 2.0, 40, 0.5, 60, 1.1,
                        as.double(.alast), numeric(.nstate),
                        .ncmt, .oral0, 1L, TRUE, 0L, 0, 0, 0, 0L, 0L,
                        as.integer(sensType), 0.001)
    }
    .a <- .call1(3L)
    .b <- .call1(32L)
    expect_identical(as.numeric(.a$val), as.numeric(.b$val))
    expect_lt(.relMax(.a$J, .b$J), 1e-12)
    expect_lt(.relMax(.a$Jg, .b$Jg), 1e-12)
  }
})
