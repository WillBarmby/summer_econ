%% Run the default Eusepi-Preston Dynare model with a custom experiment.

ir_dir = fileparts(mfilename('fullpath'));
addpath(ir_dir);
setup_ir_paths();

% Start from the complete, validated benchmark experiment.
experiment = make_dynare_ir_config();

% Edit these experiment choices.
experiment.random_seed = 20260701;
experiment.draw_count = 100;
experiment.training_periods = 2000;
experiment.ir_periods = 63;
experiment.plot_periods = 1:40;
experiment.band_probabilities = [0.25 0.75];

% Explosion handling remains explicit. Explosive draws are reported, not hidden.
experiment.explosion_policy.magnitude_limit = 1000;
experiment.explosion_policy.reject_nonfinite = true;
experiment.explosion_policy.variable_indices = 1:13;

% Keep the default structural model and E&P infinite-horizon learning setup.
mod_path = fullfile(ir_dir, 'harness', 'models', 'ep13_ih_re_linear.mod');
learning = ep_ih_learning_config();
output_dir = fullfile(ir_dir, 'artifacts', 'dynare_quantities_custom');

artifact = run_dynare_quantities_irfs( ...
    mod_path, learning, experiment, output_dir);

fprintf('Saved custom experiment to:\n  %s\n', output_dir);
