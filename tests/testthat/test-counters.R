test_that("delta memo override returns the previous setting", {
  .prev <- .linCmtDeltaMemo(1L)
  expect_identical(.linCmtDeltaMemo(0L), 1L)
  expect_identical(.linCmtDeltaMemo(.prev), 0L)
})

test_that("sequential statistics are named integers and reset", {
  .s <- .linCmtSeqStats(TRUE)
  expect_type(.s, "integer")
  expect_false(is.null(names(.s)))
  expect_true(all(.linCmtSeqStats(FALSE) == 0L))
})

test_that("carry hooks report the sentinel range and toggle the fast path", {
  expect_identical(.linCmtCarrySentinelMax(), 8L)
  .prev <- .linCmtCarrySetFast(FALSE)
  expect_false(.linCmtCarrySetFast(.prev))
  expect_named(.linCmtCarryFastStats(TRUE), c("advCalls", "advFast"))
})

test_that("sensitivity and thread observers reset", {
  .linCmtBSensTypesSeen(TRUE)
  expect_length(.linCmtBSensTypesSeen(FALSE), 0L)
  .linCmtBThreadsSeen(TRUE)
  expect_identical(.linCmtBThreadsSeen(FALSE), 0L)
})
