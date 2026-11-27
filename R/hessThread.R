#' Does this build let an estimator switch the second-order steps per thread?
#'
#' The C callable `linCmtSetHessThread(int)` (registered with
#' `R_RegisterCCallable()`) says, on the solving thread, whether the model
#' being solved reads the second-order `linCmtB()` values.  An estimator that
#' solves several models concurrently checks for it with this marker before
#' asking for the callable.
#' @return `TRUE`
#' @keywords internal
#' @noRd
.linCmtHessThread <- function() TRUE
