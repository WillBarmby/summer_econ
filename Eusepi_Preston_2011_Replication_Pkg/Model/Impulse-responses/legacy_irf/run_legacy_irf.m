function result = run_legacy_irf(config)
%% RUN_LEGACY_IRF Isolated adapter for the historical workspace entrypoint.

validate_ir_config(config);
reference = make_ir_config();
allowed = {'n_draws','learning','store_output','output_file','output_var','output_dir'};
actual_main = rmfield(config.main,allowed);
reference_main = rmfield(reference.main,allowed);
if ~isequaln(actual_main,reference_main)
    error('LegacyIRF:UnsupportedConfiguration', ...
        'The frozen legacy adapter only supports the historical model configuration.');
end

model_dir = fileparts(fileparts(mfilename('fullpath')));
skip_clear = true;
imp_resp_n_draws = config.main.n_draws;
imp_resp_learning = config.main.learning;
imp_resp_store = false;
run(fullfile(model_dir,'Main_imp_resp_Sept_2009.m'));

result = struct('imp_resp_vec',{imp_resp_vec}, ...
    'median_imp_resp_vec',{median_imp_resp_vec},'low_band',{low_band}, ...
    'up_band',{up_band},'implementation',"legacy-workspace-adapter");
end
