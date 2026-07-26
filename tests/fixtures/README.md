# Numerical Fixtures

`ep_engine_reference.mat` contains structural matrices, RE laws, one fixed shock
sequence, and short paper-EE/IH paths generated from the verified implementation
at commit `ea47484`. Tests read this compact fixture without executing the
frozen legacy implementation.

`ep_experiment_reference.mat` contains statuses and pointwise RE/learning
summaries for the retained 100-draw baseline and zero-deterministic-growth
experiments. Its provenance is Git tag `ep-verification-v1`; it contains no
executable code and lets acceptance tests remain independent of the old tree.
