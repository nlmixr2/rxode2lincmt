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
