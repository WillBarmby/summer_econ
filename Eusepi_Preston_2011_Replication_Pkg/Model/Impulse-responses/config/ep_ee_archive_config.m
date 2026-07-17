function config = ep_ee_archive_config()
%% EP_EE_ARCHIVE_CONFIG Reproducible defaults for the E&P EE experiment.
% The archive used path_length=5162, retained observations 5000:end after
% transforming the path (162 observations), HP lambda 1600, shock scale
% exp(-0.144), and 5,000 Monte Carlo replications. The archive did not save
% an RNG seed. This reconstruction supplies one and defaults to 100 draws so
% an ordinary run is practical. Set n_draws=5000 for the historical scale.

config=struct('gain',0.002,'n_draws',100,'seed',20260717, ...
    'path_length',5162,'sample_start',5000,'hp_lambda',1600, ...
    'gamma_bar',exp(0.0053),'shock_scale',exp(-0.144));
end
