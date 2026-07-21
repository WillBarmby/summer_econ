%% Run the standard comparison with persistent NK technology.

ir_dir=fileparts(mfilename('fullpath'));
addpath(ir_dir);
setup_ir_paths();

% Keep the standard 100 draws, 2,000 training periods, gain, seed, horizon,
% shock scales, and one-percent RE output-impact normalization. Change only
% the persistence of the NK technology-level process.
config=learning_comparison_config();
config.nk_technology_persistence=0.99;

output_dir=fullfile(ir_dir,'artifacts','comparisons','nk_rho_099');
artifact=run_learning_comparison_panels(config,output_dir);

fprintf('Saved the rho_technology=0.99 comparison to:\n  %s\n',output_dir);
