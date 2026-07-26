# Replication Lineage

The complete Eusepi-Preston reconstruction remains in the frozen
`Eusepi_Preston_2011_Replication_Pkg/` tree and at Git tag
`ep-verification-v1`. That implementation remains runnable during the clean
interface transition.

The verified claims at the transition point are:

- the 13-equation Dynare IH representation reproduces the released baseline
  under shared innovations, including arbitrary-belief mappings and complete
  learning paths, within `1e-10`;
- the archive EE variant reproduces the released EE learning path within
  numerical precision; and
- the paper-faithful EE variant implements the consumption-forecasting contract
  described after equation (17), but is not claimed to be path-equivalent to
  the released EE code because their perceived laws of motion differ.

The historical milestone commits and detailed test commands are documented in
`Eusepi_Preston_2011_Replication_Pkg/Model/Impulse-responses/REPLICATION_STATUS.md`
at the verification tag. New public commands must not add that tree to the
MATLAB path or call its functions at runtime.
