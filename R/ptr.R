#' External pointers to the linear compartment entry points
#'
#' rxode2 reads this list from its `.onLoad()` and calls the linear
#' compartment kernels through it; see `inst/include/rxode2lincmtPtrs.h` for
#' the consumer contract.  The list is append-only and its order is fixed.
#'
#' @return named list of external pointers
#' @export
#' @keywords internal
#' @examples
#' names(.rxode2lincmtPtr())
.rxode2lincmtPtr <- function() {
  .Call(`_rxode2lincmt_ptr`)
}

#' Register the host table from rxode2
#'
#' rxode2 calls this from its `.onLoad()` with the struct offsets and host
#' functions described in `inst/include/rxode2lincmtHost.h`.  Nothing is
#' validated; values are copied with bounds limits only.
#'
#' @param host list built by rxode2 (offsets followed by external pointers)
#' @return `NULL`, invisibly
#' @export
#' @keywords internal
.rxode2lincmtIniHost <- function(host) {
  invisible(.Call(`_rxode2lincmt_iniHost`, host))
}

#' Inspect the registered host table
#'
#' Test hook: the struct offsets currently held (-1 before registration) and
#' whether each host function has been bound.
#'
#' @return list with `offsets` (integer) and `fns` (named logical)
#' @export
#' @keywords internal
#' @examples
#' .rxode2lincmtHostInfo()$fns
.rxode2lincmtHostInfo <- function() {
  .Call(`_rxode2lincmt_hostInfo`)
}

#' Host table field names
#'
#' Test hook: the `struct_field` names of the offset table in wire order.
#'
#' @return character vector
#' @export
#' @keywords internal
#' @examples
#' head(.rxode2lincmtHostFieldNames())
.rxode2lincmtHostFieldNames <- function() {
  .Call(`_rxode2lincmt_hostFieldNames`)
}
