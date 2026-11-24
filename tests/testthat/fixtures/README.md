# Test fixtures

## closed_form_mpmath.txt

High-precision reference values for the 1-3 compartment closed forms: the
central concentration, its first and second parameter derivatives, computed
from a matrix exponential of the compartment generator in mpmath at 60
digits.  One case per line:

`kind;params;t;ii;dur;value;grad;hess upper triangle (row-major);peripheral concentrations`

with a 100-unit dose, parameters `(CL, V[, Q, V2[, Q3, V3]][, KA])`.

Copied unchanged from FeRx (`ferx-core/tests/data/closed_form_mpmath.txt`,
commit 22d3184a00de59e2aa51f28327f06be00e4a45ef), MIT License,
Copyright (c) 2026 the FeRx core developer team.
