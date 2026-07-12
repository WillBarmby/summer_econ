function test_nk_plugin()
%% TEST_NK_PLUGIN Demonstrate structural, EE-learning, and results reuse.

model_dir=fullfile(fileparts(fileparts(mfilename('fullpath'))),'models');
model=load_dynare_71_linear_model(fullfile(model_dir,'nk3_linear.mod'));
config=nk3_plugin_config();
[plugin,state,fixed]=make_linear_ee_plugin(model,0.001);
assert(fixed.converged);
rng(73); shocks=randn(numel(model.shock_names),80)*0.01;
policy=struct('magnitude_limit',1000,'reject_nonfinite',true, ...
    'variable_indices',1:numel(model.variable_names));
run=simulate_learning_path(plugin,shocks,zeros(numel(model.variable_names),1),state,policy);
assert(~run.invalid);
formulation=struct('name',config.formulation);
results=build_research_results(model,formulation,run,config.observables, ...
    struct('seed',73,'gain',0.001,'dynare_version',model.dynare.version));
assert(isfield(results.observables,'inflation'));
assert(results.diagnostics.invalid_run_share==0);
fprintf('NK structural/EE-learning/results plug-in test passed.\n');
end
