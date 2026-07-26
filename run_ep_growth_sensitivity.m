function growth = run_ep_growth_sensitivity(varargin)
%% RUN_EP_GROWTH_SENSITIVITY Compare original and zero deterministic growth.
% This runner executes only E&P EE and IH. Both gamma_bar calibrations use the
% same seed, standardized innovations, and structural growth impulse.

root = setup_project();
if nargin==0
    config = ep_experiment_config();
    output_dir = fullfile(root,'results','ep_growth_sensitivity');
elseif nargin==2
    config = varargin{1};
    output_dir = varargin{2};
else
    error('EPResearch:RequiredArguments', ...
        'Supply both a complete config and output directory, or neither.');
end
if ~isfolder(output_dir), mkdir(output_dir); end
baseline_config = config;
baseline_config.gamma_bar = exp(0.0053);
zero_growth_config = config;
zero_growth_config.gamma_bar = 1;
baseline = run_ep_experiment(baseline_config, ...
    fullfile(output_dir,'original_growth'),'ep_original_growth');
zero_growth = run_ep_experiment(zero_growth_config, ...
    fullfile(output_dir,'zero_growth'),'ep_zero_growth');
assert(isequal(baseline.standardized_innovations, ...
    zero_growth.standardized_innovations),'EPResearch:UnpairedGrowthTest', ...
    'Growth sensitivity did not use identical random draws.');
differences = cell(1,2);
for j = 1:2
    differences{j} = struct('id',baseline.results{j}.id, ...
        'learning_median',zero_growth.results{j}.summary.learning_median- ...
        baseline.results{j}.summary.learning_median, ...
        're',zero_growth.results{j}.summary.re-baseline.results{j}.summary.re);
end
growth = struct('experiment','ep_growth_sensitivity', ...
    'description',['gamma_bar=1 minus gamma_bar=exp(0.0053), holding ' ...
    'innovations and the technology-growth impulse fixed'], ...
    'config',config,'baseline',baseline,'zero_growth',zero_growth, ...
    'differences',{differences},'figure_files',struct(),'output_file', ...
    fullfile(output_dir,'ep_growth_sensitivity.mat'));
growth.figure_files = save_ep_growth_panels(growth,output_dir);
save(growth.output_file,'-struct','growth','-v7.3');
end
