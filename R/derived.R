#' Derived linear compartment parameters (engine for `rxode2::rxDerived()`)
#'
#' Low-level entry point: rxode2's `rxDerived()` parses the parameter names
#' and calls this with the compartment count, parameterization and a list of
#' parameter vectors.  Use `rxode2::rxDerived()` instead of calling it
#' directly.
#'
#' @param ncmt number of compartments (1-3, double)
#' @param oral oral flag (double)
#' @param w2 parser weight flag (double)
#' @param trans parameterization number (double)
#' @param inp list of parameter vectors in parser order
#' @param digits significant digits to round to (0 for no rounding)
#' @return data frame of derived parameters
#' @export
#' @keywords internal
.calcDerived <- function(ncmt, oral, w2, trans, inp, digits = 0) {
  .Call(`_rxode2lincmt_calcDerived`, ncmt, oral, w2, trans, inp, digits)
}
