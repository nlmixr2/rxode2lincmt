#' @details The closed-form linear compartment solutions follow the idea of
#'   the 'wnl' package by Kyun-Seop Bae
#'   (<https://CRAN.R-project.org/package=wnl>); the implementation here is
#'   different.
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @useDynLib rxode2lincmt, .registration = TRUE
#' @importFrom Rcpp sourceCpp
#' @importFrom RcppParallel RcppParallelLibs
## usethis namespace: end
NULL
