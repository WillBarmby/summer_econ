function model = load_nonlinear_dynare_model(mod_path,varargin)
%% LOAD_NONLINEAR_DYNARE_MODEL Linearize a stationary nonlinear Dynare model.
% Dynare solves the nonlinear model and supplies analytical first derivatives
% at its deterministic steady state. This loader then expresses those
% derivatives in the same canonical structural form used by the learning code:
%
%   D0*z_t + Dlag*z_(t-1) + Dlead*z_(t+1) + Dshock*eps_t = 0.
%
% Here z is measured in percentage-point deviation units. For a positive level
% variable x, one unit of z means x moves by steady_state(x)/100. Variables with
% zero steady state need an explicit DeviationScales entry. For example,
%
%   'DeviationScales',struct('gamma_x',0.01)
%
% states that one canonical unit of gamma_x is 0.01 in the nonlinear model,
% i.e. one percentage point of log technology growth.

parser = inputParser;
addParameter(parser,'ParameterOverrides',struct(), ...
    @(value) isstruct(value) && isscalar(value));
addParameter(parser,'DeviationScales',struct(), ...
    @(value) isstruct(value) && isscalar(value));
parse(parser,varargin{:});
overrides = parser.Results.ParameterOverrides;
scale_overrides = parser.Results.DeviationScales;
validate_numeric_struct(overrides,'parameter override');
validate_numeric_struct(scale_overrides,'deviation scale');

%% Run Dynare in an isolated temporary directory.
% Dynare generates MATLAB packages and publishes M_ and oo_ globally. Running
% from a temporary copy prevents generated files and global working-directory
% assumptions from leaking into the research tree.
runtime = configure_dynare();
reset_dynare_state();
assert(isfile(mod_path),'EPResearch:MissingModel', ...
    'Dynare model not found: %s',mod_path);
source = fileread(mod_path);
assert(isempty(regexp(source, ...
    'model\s*\([^;)]*linear[^;)]*\)\s*;','once')), ...
    'EPResearch:LinearModel', ...
    'Use load_linear_dynare_model for an explicit model(linear) file.');

work = tempname;
mkdir(work);
cleanup_work = onCleanup(@() remove_work_directory(work));
[~,name,extension] = fileparts(mod_path);
assert(isvarname(name),'EPResearch:InvalidModelName', ...
    'The .mod filename must be a valid MATLAB identifier.');
copyfile(mod_path,fullfile(work,[name extension]));
old_directory = pwd;
cleanup_directory = onCleanup(@() cd(old_directory));
cd(work);
evalin('base',make_dynare_command(name,overrides));

global M_ oo_ %#ok<GVMIS>
assert(strcmp(M_.fname,name),'EPResearch:DynareState', ...
    'Dynare returned state for an unexpected model.');
assert(isfield(oo_,'dr') && ~isempty(oo_.dr), ...
    'EPResearch:MissingDecisionRule', ...
    'Dynare did not return a first-order decision rule.');

%% Build the steady-state dynamic input expected by Dynare 7.1.
% Generated derivative functions use the dense vector
% [all lags; all current values; all leads]. At a deterministic steady state,
% every copy contains the same level value. unpack_dynare_jacobian separately
% checks lead_lag_incidence and verifies that inactive derivatives are zero.
n = M_.endo_nbr;
steady_state = oo_.steady_state(:);
assert(numel(steady_state)==n && all(isfinite(steady_state)), ...
    'EPResearch:InvalidSteadyState', ...
    'Dynare did not return a finite steady state for every variable.');
dynamic_values = repmat(steady_state,3,1);
exo_steady_state = oo_.exo_steady_state(:).';

%% Evaluate residuals and Dynare's analytical first derivatives.
% The derivative columns follow Dynare's compact dynamic-vector ordering,
% followed by one column for each stochastic exogenous variable.
residual_function = str2func([name '.dynamic_resid']);
residual = residual_function(dynamic_values,exo_steady_state, ...
    M_.params,steady_state);
assert(max(abs(residual))<1e-10,'EPResearch:NonzeroSteadyStateResidual', ...
    'Nonlinear steady-state residual is %.3g.',max(abs(residual)));
g1_function = str2func([name '.dynamic_g1']);
jacobian = full(g1_function(dynamic_values,exo_steady_state,M_.params, ...
    steady_state,M_.dynamic_g1_sparse_rowval, ...
    M_.dynamic_g1_sparse_colval,M_.dynamic_g1_sparse_colptr));
level_matrices = unpack_dynare_jacobian(jacobian,M_);

%% Convert additive level deviations to percentage-point deviations.
% Write the nonlinear perturbation as x = x_bar + S*z. Substitution into the
% first-order residual multiplies every endogenous Jacobian block by S. Shock
% columns are unchanged because the exogenous innovations already retain their
% declared numerical units.
variable_names = M_.endo_names(:).';
scales = default_deviation_scales(steady_state,variable_names,scale_overrides);
scale_matrix = diag(scales);
current = level_matrices.current*scale_matrix;
lag = level_matrices.lag*scale_matrix;
lead = level_matrices.lead*scale_matrix;

%% Transform Dynare's RE decision rule into the same percentage-point units.
% Dynare's raw rule maps level deviations into level deviations. If
% x_t = T*x_(t-1)+B*eps_t, then z_t = S^(-1)*T*S*z_(t-1)+S^(-1)*B*eps_t.
% Scaling the compact ghx and ghu matrices here lets the existing
% extract_re_law function operate without any nonlinear-model special case.
level_rule = oo_.dr;
decision_rule = level_rule;
row_scale = scales(level_rule.order_var);
state_scale = scales(level_rule.state_var);
decision_rule.ghx = diag(1./row_scale)*level_rule.ghx*diag(state_scale);
decision_rule.ghu = diag(1./row_scale)*level_rule.ghu;

%% Assemble and validate the model-independent canonical contract.
equation_names = equation_tags(M_,n);
calibration = parameter_struct(M_);
verify_overrides(calibration,overrides);
model = struct('name',name, ...
    'backend','dynare-7.1-nonlinear-first-order', ...
    'variable_names',{variable_names}, ...
    'shock_names',{M_.exo_names(:).'}, ...
    'equation_names',{equation_names}, ...
    'current',current,'lag',lag,'lead',lead, ...
    'shock',level_matrices.shock, ...
    'calibration',calibration);
model.re = struct('source','dynare-analytical-first-order', ...
    'decision_rule',decision_rule,'steady_state',zeros(n,1), ...
    'level_decision_rule',level_rule);
model.transformation = struct( ...
    'description','one unit is one percentage-point deviation', ...
    'level_steady_state',steady_state,'deviation_scales',scales, ...
    'scale_overrides',scale_overrides);
model.dynare = struct('version',runtime.version, ...
    'parameter_overrides',overrides,'steady_state_residual',residual);
validate_structural_model(model);
clear cleanup_directory cleanup_work
end

function scales = default_deviation_scales(steady_state,names,overrides)
% Positive steady-state variables default to proportional percentage units.
scales = steady_state/100;
override_names = fieldnames(overrides);
for j = 1:numel(override_names)
    name = override_names{j};
    index = find(strcmp(names,name),1);
    assert(~isempty(index),'EPResearch:UnknownScale', ...
        'Dynare model has no variable named %s.',name);
    scales(index) = overrides.(name);
end
missing = find(~isfinite(scales) | scales<=0);
assert(isempty(missing),'EPResearch:MissingDeviationScale', ...
    'Supply positive DeviationScales for: %s.', ...
    strjoin(names(missing),', '));
end

function calibration = parameter_struct(M)
% Preserve the effective Dynare calibration in the saved experiment artifact.
calibration = struct();
for j = 1:numel(M.param_names)
    calibration.(M.param_names{j}) = M.params(j);
end
end

function names = equation_tags(M,n)
% Prefer human-readable [name='...'] tags from the .mod model block.
names = arrayfun(@(j) sprintf('equation_%d',j),1:n, ...
    'UniformOutput',false);
if isfield(M,'equations_tags') && ~isempty(M.equations_tags)
    tags = M.equations_tags;
    for j = 1:size(tags,1)
        if strcmp(tags{j,2},'name')
            names{tags{j,1}} = tags{j,3};
        end
    end
end
end

function validate_numeric_struct(values,description)
% Both parameter and scale overrides must be safe scalar name/value pairs.
names = fieldnames(values);
for j = 1:numel(names)
    value = values.(names{j});
    assert(isvarname(names{j}) && isnumeric(value) && isscalar(value) && ...
        isreal(value) && isfinite(value),'EPResearch:InvalidOverride', ...
        '%s values require valid names and finite real scalars.',description);
end
end

function command = make_dynare_command(name,overrides)
% Dynare macro definitions allow configs to override parameters without edits.
options = {'noclearall','nolog'};
names = fieldnames(overrides);
for j = 1:numel(names)
    options{end+1} = sprintf('-D%s=%.17g', ...
        names{j},overrides.(names{j})); %#ok<AGROW>
end
command = sprintf('dynare %s %s',name,strjoin(options,' '));
end

function verify_overrides(calibration,overrides)
% Fail clearly if a requested macro override was absent or ignored by the file.
names = fieldnames(overrides);
for j = 1:numel(names)
    name = names{j};
    assert(isfield(calibration,name),'EPResearch:UnknownOverride', ...
        'Dynare model has no parameter named %s.',name);
    tolerance = 1e-12*max(1,abs(overrides.(name)));
    assert(abs(calibration.(name)-overrides.(name))<=tolerance, ...
        'EPResearch:UnusedOverride', ...
        'Parameter override %s was not applied.',name);
end
end

function remove_work_directory(work)
% Generated Dynare packages are diagnostic scratch data, not research output.
if isfolder(work)
    rmdir(work,'s');
end
end
