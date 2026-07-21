%% Run the standard E&P and NK comparison with IID NK technology.

ir_dir=fileparts(mfilename('fullpath'));
addpath(ir_dir);
setup_ir_paths();

% Standard experiment: 100 draws, 2,000 training periods, gain 0.002,
% a 40-quarter horizon, and shocks normalized to a one-percent RE output
% impact. The NK technology-level shock is explicitly i.i.d.
config=learning_comparison_config();
config.nk_technology_persistence=0;

output_dir=fullfile(ir_dir,'artifacts','comparisons', ...
    'iid_technology_output_1pct');
artifact=run_learning_comparison_panels(config,output_dir);

fprintf('Saved the rho_technology=0 comparison to:\n  %s\n',output_dir);
