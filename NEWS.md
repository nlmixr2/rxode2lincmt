# rxode2lincmt 0.1.0

## New features

- Initial release.  The analytic one, two and three compartment linear
  solutions, their 'stan' gradients, the eigen decompositions (`solComp2()`,
  `solComp3()`) and the derived-parameter conversions behind
  `rxode2::rxDerived()` moved here from 'rxode2', so 'rxode2' no longer
  compiles 'stan'.  'rxode2' reaches the compiled kernels through an
  external-pointer table and hands this package the struct offsets it needs,
  so neither package shares struct layouts with the other.
