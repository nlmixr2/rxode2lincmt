# Loading TBB (RcppParallel's library) is what CRAN's gcc-UBSAN check reports,
# so neither loading this package nor reverse-mode AD may load it.
test_that("reverse-mode gradients do not load the TBB library", {
  skip_if_not(file.exists("/proc/self/maps"))
  .a <- numeric(.lcNalast(3L, 1L, TRUE))
  .a[1:4] <- c(50, 20, 5, 2)
  .r <- linCmtModelDouble(0.7, 1.0, 20, 2.0, 40, 0.5, 60, 1.1,
                          .a, rep(0, 4), 3L, 1L, 1L, TRUE,
                          0L, 0, 0, 0, 0L, 0L, 31L, 0.001)
  expect_true(all(is.finite(.r$J)))
  expect_false("RcppParallel" %in% loadedNamespaces())
  expect_false(any(grepl("libtbb", readLines("/proc/self/maps"), fixed = TRUE)))
})
