# rxode2lincmt: Linear Compartment Model Solutions and Gradients for 'rxode2'

Analytic one, two and three compartment linear pharmacokinetic solutions
with their parameter gradients from 'stan' automatic differentiation
(Carpenter et al (2015)
[doi:10.48550/arXiv.1509.07164](https://doi.org/10.48550/arXiv.1509.07164)
), eigen decompositions and derived-parameter conversions used by
'rxode2' (Wang, Hallow and James (2016)
[doi:10.1002/psp4.12052](https://doi.org/10.1002/psp4.12052) ). Split
out of 'rxode2' so its installation does not compile 'stan' AD items
which made it take too long to compile by itself. The closed-form
solutions follow the idea of the 'wnl' package (Bae,
<https://CRAN.R-project.org/package=wnl>), though the implementation
here is different.

## Details

The closed-form linear compartment solutions follow the idea of the
'wnl' package by Kyun-Seop Bae
(<https://CRAN.R-project.org/package=wnl>); the implementation here is
different.

## See also

Useful links:

- <https://nlmixr2.github.io/rxode2lincmt/>

- <https://github.com/nlmixr2/rxode2lincmt/>

- Report bugs at <https://github.com/nlmixr2/rxode2lincmt/issues/>

## Author

**Maintainer**: Matthew L. Fidler <matthew.fidler@gmail.com>
([ORCID](https://orcid.org/0000-0001-8538-6691))

Authors:

- Matthew L. Fidler <matthew.fidler@gmail.com>
  ([ORCID](https://orcid.org/0000-0001-8538-6691))

Other contributors:

- Richard Upton \[contributor\]
