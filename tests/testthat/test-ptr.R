test_that("the lincmt pointer table keeps its released order", {
  .p <- .rxode2lincmtPtr()
  .frozen <- c("linCmtA", "linCmtB", "ensureLinCmtA", "ensureLinCmtB",
               "linCmtBindFree", "linCmtScaleInitPar", "linCmtScaleInitN",
               "linCmtZeroJac", "linCmtFreeInd")
  expect_gte(length(.p), length(.frozen))
  expect_identical(names(.p)[seq_along(.frozen)], .frozen)
  expect_true(all(vapply(.p, typeof, character(1)) == "externalptr"))
  expect_true(all(.Call(`_rxode2lincmt_ptrNonNull`)))
})
