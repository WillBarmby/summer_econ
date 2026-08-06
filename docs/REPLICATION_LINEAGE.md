# Replication Lineage

> **Historical documentation.** This records verification of the former
> experiment implementation. It is intentionally retained outside the active
> model-loader and learning-engine contract.

The complete Eusepi–Preston reconstruction is preserved at Git tag
`ep-verification-v1`, where the frozen
`Eusepi_Preston_2011_Replication_Pkg/` tree remains runnable. That tree is not
tracked on the active clean-interface branch.

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
at the verification tag. New public commands must not restore that tree as a
runtime dependency.

The clean interface carries forward that evidence through compact numerical
fixtures in `tests/fixtures/`. Run `run_acceptance_tests` to compare the active
100-draw EE/IH baseline and deterministic-growth sensitivity with those saved
references. The fixture-based test is a regression check against the tagged
lineage; it does not execute the archived implementation.
