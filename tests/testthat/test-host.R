test_that("the host field list keeps its released order", {
  .frozen <- c("rx_subjects", "rx_op", "rx_ndiff", "rx_sensType", "rx_linCmtScale",
               "rx_linCmtSensPhi", "rx_linCmtSuspect", "rx_linCmtForwardMax",
               "op_neq", "op_inits", "op_numLin", "op_linOffset", "op_linCmtLagMask",
               "op_linCmtOriginMask", "ind_cmt", "ind_doSS", "ind_idose", "ind_idx",
               "ind_InfusionRate", "ind_ix", "ind_ndoses", "ind__rxFlag", "ind_solvedIdx",
               "ind_tout", "ind_tprior", "ind_neqOverride", "ind_solve", "ind_evid",
               "ind_extraDoseEvid", "ind_dose", "ind_extraDoseDose", "ind_linCmtSave",
               "ind_linCmtAlast", "ind_linSS", "ind_linSSbolusCmt", "ind_linSStau",
               "ind_linSSvar", "ind_linH", "ind_linCmtHparIndex", "ind_linCmtH",
               "ind_linCmtHV", "ind_linCmtRateHist", "ind_linCmtRateHistCap",
               "ind_linCmtRateHistW", "ind_linCmtCarryT", "ind_linCmtCarryTlast",
               "ind_linCmtCarryPrevTheta", "ind_linCmtCarryVarying", "ind_linCmtBind",
               "ind_linCmtOrigin", "ind_linCmtOriginSeeded", "ind_linCmtOriginOut",
               "ind_linCmtOriginOutSeeded", "ind_linCmtOriginIdx", "ind_linCmtOriginSS",
               "ind_linCmtOriginHist", "ind_linCmtOriginHistCap", "ind_linCmtOriginHistW")
  .nm <- .rxode2lincmtHostFieldNames()
  expect_gte(length(.nm), length(.frozen))
  expect_identical(.nm[seq_along(.frozen)], .frozen)
  expect_length(.rxode2lincmtHostInfo()$offsets, 3L + length(.nm))
})

test_that("before registration every offset is unset and no host function is bound", {
  skip_if("rxode2" %in% loadedNamespaces())
  .info <- .rxode2lincmtHostInfo()
  expect_true(all(.info$offsets == -1L))
  expect_named(.info$fns, c("getTime", "rxThreadSlot", "getRxSolve"))
  expect_false(any(.info$fns))
  expect_error(.linCmtCarryLiveTest(0L, 1, 0, matrix(1, 1, 7), 1L, 0L, 1L, -5L, 0L),
               "not linked")
})

test_that("the carry cap is 8 until a host registers", {
  skip_if("rxode2" %in% loadedNamespaces())
  expect_identical(.linCmtCarryMaxPairs(), 8L)
})

test_that("a registered host's carry cap is the one in use", {
  .o <- .rxode2lincmtHostInfo()$offsets
  on.exit(.rxode2lincmtIniHost(list(.o)))
  for (.cap in c(1L, 8L, 32L)) {
    .w <- .o
    .w[2] <- .cap
    .rxode2lincmtIniHost(list(.w))
    expect_identical(.linCmtCarryMaxPairs(), .cap)
    expect_identical(.rxode2lincmtHostInfo()$offsets, .w)
  }
})

test_that("a host with more carry columns than this package supports is refused", {
  # nothing is copied, so the offsets already held stay in use
  .o <- .rxode2lincmtHostInfo()$offsets
  .cap0 <- .linCmtCarryMaxPairs()
  .w <- .o
  .w[1] <- 1L
  .w[2] <- 33L
  expect_error(
    .rxode2lincmtIniHost(list(.w)),
    "rxode2 has 33 linCmt() carry columns, but this rxode2lincmt supports at most 32; update rxode2lincmt",
    fixed = TRUE
  )
  expect_identical(.rxode2lincmtHostInfo()$offsets, .o)
  expect_identical(.linCmtCarryMaxPairs(), .cap0)
  .w[2] <- 0L
  expect_error(
    .rxode2lincmtIniHost(list(.w)),
    "rxode2 reports 0 linCmt() carry columns; it needs at least 1",
    fixed = TRUE
  )
  expect_identical(.rxode2lincmtHostInfo()$offsets, .o)
})

test_that("a carry restart at a reset clears only the columns written, at the host's stride", {
  # an 8-column host with pairs 0-2 written: the array is 4 rows of 8, and
  # nothing past it (the next fields of a real subject) may be touched
  .r <- .Call(`_rxode2lincmt_carryRestartProbe`, 8L, 3L)
  .m <- matrix(.r[1:32], nrow = 4, byrow = TRUE)
  expect_true(all(.m[, 1:3] == 0))
  expect_true(all(.m[, 4:8] == 7))
  expect_true(all(.r[33:136] == 7))
  # Tlast restarts
  expect_true(is.nan(.r[137]))
  # a 32-column host with every pair written clears its whole array, and no more
  .r <- .Call(`_rxode2lincmt_carryRestartProbe`, 32L, 32L)
  expect_true(all(.r[1:128] == 0))
  expect_true(all(.r[129:136] == 7))
  # nothing written, nothing cleared
  .r <- .Call(`_rxode2lincmt_carryRestartProbe`, 8L, 0L)
  expect_true(all(.r[1:136] == 7))
})

# linCmtEventJac() on a copy of `a`
.eventJac <- function(a, numLin, depotLin, numLinSens, c, type, factor = 1) {
  .Call(`_rxode2lincmt_eventJacProbe`, a, numLin, depotLin, numLinSens, c, type, factor)
}

test_that("a replace or multiply makes only its compartment's Jacobian row follow", {
  # 1-cmt: the amount, then d(A)/d(p1, v1)
  .a <- c(5, 1.5, -2)
  expect_identical(.eventJac(.a, 1L, 0L, 2L, 0L, 0L), c(5, 0, 0))
  expect_identical(.eventJac(.a, 1L, 0L, 2L, 0L, 1L, 0.5), c(5, 0.75, -1))
  # 2-cmt: two amounts, then a row of 4 per compartment
  .a <- c(5, 3, 1:4, 5:8)
  expect_identical(.eventJac(.a, 2L, 0L, 8L, 1L, 0L), c(5, 3, 1:4, rep(0, 4)))
  expect_identical(.eventJac(.a, 2L, 0L, 8L, 0L, 1L, 2), c(5, 3, 2 * (1:4), 5:8))
  # 1-cmt oral: depot and central amounts, central's row of 3, then the
  # depot's one entry (ka)
  .a <- c(4, 6, 1:3, 9)
  expect_identical(.eventJac(.a, 2L, 1L, 4L, 1L, 0L), c(4, 6, 0, 0, 0, 9))
  expect_identical(.eventJac(.a, 2L, 1L, 4L, 0L, 1L, 0.25), c(4, 6, 1:3, 2.25))
  expect_identical(.eventJac(.a, 2L, 1L, 4L, 0L, 0L), c(4, 6, 1:3, 0))
  # a multiply by 0 clears the row too
  expect_identical(.eventJac(.a, 2L, 1L, 4L, 1L, 1L, 0), c(4, 6, 0, 0, 0, 9))
  # a Jacobian of another size, or a compartment outside the block, is left
  expect_identical(.eventJac(.a, 2L, 1L, 3L, 1L, 0L), .a)
  expect_identical(.eventJac(.a, 2L, 1L, 4L, 2L, 0L), .a)
})
