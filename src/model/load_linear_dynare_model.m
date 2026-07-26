function model = load_linear_dynare_model(mod_path,varargin)
%% LOAD_LINEAR_DYNARE_MODEL Load an explicit linear deviation-form model.
% The .mod file must declare model(linear), solve its steady state, and call a
% first-order Dynare solution command. ParameterOverrides is a scalar struct;
% each field is passed through Dynare's macroprocessor and verified afterward.
%
% The canonical structural system returned by this function is
%   D0*y_t + Dlag*y_(t-1) + Dlead*y_(t+1) + Dshock*eps_t = 0.
% Because these E&P files are explicitly linear, evaluating each residual at
% a unit perturbation recovers an exact matrix column rather than a numerical
% approximation. The temporary directory isolates Dynare's generated driver
% files, and its cleanup deliberately leaves no runtime artifact behind.

parser = inputParser;
addParameter(parser,'ParameterOverrides',struct(), ...
    @(value) isstruct(value) && isscalar(value));
parse(parser,varargin{:});
overrides = parser.Results.ParameterOverrides;
validate_overrides(overrides);

runtime = configure_dynare();
reset_dynare_state();
assert(isfile(mod_path),'EPResearch:MissingModel', ...
    'Dynare model not found: %s',mod_path);
source = fileread(mod_path);
assert(~isempty(regexp(source, ...
    'model\s*\([^;)]*linear[^;)]*\)\s*;','once')), ...
    'EPResearch:NonlinearModel', ...
    'This loader accepts only models explicitly declared model(linear).');

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
n = M_.endo_nbr;
q = M_.exo_nbr;
y = zeros(3*n,1);
x = zeros(1,q);
residual_function = str2func([name '.dynamic_resid']);
base = residual_function(y,x,M_.params,oo_.steady_state);
assert(max(abs(base))<1e-10,'EPResearch:NonzeroDeviationModel', ...
    'The model is not a zero-deviation system; residual %.3g.',max(abs(base)));

incidence = M_.lead_lag_incidence;
phase = cell(3,1);
% Dynare reports which declared variable is active at lag, current, and lead
% timing. Perturb the dense [lag; current; lead] residual input one declared
% variable at a time so the output columns stay in declaration order.
for p = 1:3
    phase{p} = zeros(n,n);
    for j = 1:n
        if incidence(p,j)>0
            perturbed = y;
            perturbed((p-1)*n+j) = 1;
            phase{p}(:,j) = residual_function(perturbed,x,M_.params, ...
                oo_.steady_state)-base;
        end
    end
end
shock = zeros(n,q);
% The same unit-residual calculation obtains the structural loading of each
% innovation. Signs are not changed here: they retain the equation-residual
% convention and are handled when the ALM system is solved.
for j = 1:q
    perturbed = x;
    perturbed(j) = 1;
    shock(:,j) = residual_function(y,perturbed,M_.params, ...
        oo_.steady_state)-base;
end

equation_names = equation_tags(M_,n);
calibration = struct();
for j = 1:numel(M_.param_names)
    calibration.(M_.param_names{j}) = M_.params(j);
end
verify_overrides(calibration,overrides);
model = struct('name',name,'backend','dynare-7.1-linear', ...
    'variable_names',{M_.endo_names(:).'}, ...
    'shock_names',{M_.exo_names(:).'}, ...
    'equation_names',{equation_names},'current',phase{2}, ...
    'lag',phase{1},'lead',phase{3},'shock',shock, ...
    'calibration',calibration);
model.re = struct('source','dynare','decision_rule',oo_.dr, ...
    'steady_state',oo_.steady_state);
model.dynare = struct('version',runtime.version, ...
    'parameter_overrides',overrides);
validate_structural_model(model);
clear cleanup_directory cleanup_work
end

function names = equation_tags(M,n)
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

function validate_overrides(overrides)
names = fieldnames(overrides);
for j = 1:numel(names)
    value = overrides.(names{j});
    assert(isvarname(names{j}) && isnumeric(value) && isscalar(value) && ...
        isreal(value) && isfinite(value),'EPResearch:InvalidOverride', ...
        'Parameter overrides require valid names and finite real scalars.');
end
end

function command = make_dynare_command(name,overrides)
options = {'noclearall','nolog'};
names = fieldnames(overrides);
for j = 1:numel(names)
    options{end+1} = sprintf('-D%s=%.17g', ...
        names{j},overrides.(names{j})); %#ok<AGROW>
end
command = sprintf('dynare %s %s',name,strjoin(options,' '));
end

function verify_overrides(calibration,overrides)
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
if isfolder(work)
    rmdir(work,'s');
end
end
