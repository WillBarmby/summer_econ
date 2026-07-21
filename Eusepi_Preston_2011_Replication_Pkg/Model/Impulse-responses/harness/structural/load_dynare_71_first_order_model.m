function model = load_dynare_71_first_order_model(mod_path,varargin)
%% LOAD_DYNARE_71_FIRST_ORDER_MODEL Linearize a nonlinear Dynare model.
%
% The .mod file must compute a deterministic steady state and execute a
% first-order solution command such as stoch_simul(order=1). Generated Dynare
% files are deleted by default; pass KeepGeneratedFiles=true to retain them
% for inspection and receive their path in model.dynare.work_directory.
% ParameterOverrides must be a scalar struct of finite numeric scalars. Each
% field is passed to Dynare's macroprocessor and verified against the effective
% parameter vector after the model is solved.
%
% The returned structural matrices describe additive deviations from the
% deterministic steady state. This loader does not impose a log/percentage
% normalization; that transformation must be explicit before comparison or
% learning.

parser=inputParser;
addParameter(parser,'KeepGeneratedFiles',false, ...
    @(value) islogical(value) && isscalar(value));
addParameter(parser,'ParameterOverrides',struct(), ...
    @(value) isstruct(value) && isscalar(value));
parse(parser,varargin{:});
keep_generated_files=parser.Results.KeepGeneratedFiles;
parameter_overrides=parser.Results.ParameterOverrides;
validate_parameter_overrides(parameter_overrides);

runtime=configure_dynare_71();
reset_dynare_71_globals();
assert(isfile(mod_path),'Dynare model not found: %s',mod_path);
source=fileread(mod_path);
% This textual check is a guardrail for controlled project files, not a
% substitute for parsing the Dynare model language.
assert(isempty(regexp(source,'model\s*\([^;)]*linear[^;)]*\)\s*;','once')), ...
    'DynareFirstOrder:ExplicitlyLinear', ...
    'Use load_dynare_71_linear_model for model(linear) files.');

work=tempname;
mkdir(work);
cleanup_work=onCleanup(@() remove_work_directory(work,keep_generated_files));
[~,fname,ext]=fileparts(mod_path);
assert(isvarname(fname),'DynareFirstOrder:InvalidModelName', ...
    'The .mod filename must be a valid MATLAB identifier.');
copyfile(mod_path,fullfile(work,[fname ext]));
old=pwd;
cleanup_directory=onCleanup(@() cd(old));
cd(work);
evalin('base',make_dynare_command(fname,parameter_overrides));

% Dynare publishes model and solution state globally.
global M_ oo_ %#ok<GVMIS>
assert(strcmp(M_.fname,fname));
assert(M_.eq_nbr==M_.endo_nbr,'DynareFirstOrder:NonSquareModel', ...
    'A square transformed Dynare model is required.');
assert(numel(oo_.steady_state)==M_.endo_nbr && ...
    all(isfinite(oo_.steady_state)),'DynareFirstOrder:InvalidSteadyState', ...
    'Dynare did not return a finite deterministic steady state.');
required_dr={'order_var','state_var','ghx','ghu'};
assert(isfield(oo_,'dr') && isstruct(oo_.dr) && ...
    all(isfield(oo_.dr,required_dr)) && ...
    isequal(size(oo_.dr.ghu),[M_.endo_nbr,M_.exo_nbr]), ...
    'DynareFirstOrder:MissingDecisionRule', ...
    ['Dynare did not return a usable first-order decision rule. The .mod ' ...
     'file must execute a command such as stoch_simul(order=1).']);

% Dynare 7.1 generated dynamic functions use the dense vector
% [y(-1); y; y(+1)] even when a variable is absent at one of those phases.
y=repmat(oo_.steady_state,3,1);
x=oo_.exo_steady_state(:).';
residfun=str2func([fname '.dynamic_resid']);
[residual,T_order,T]=residfun(y,x,M_.params,oo_.steady_state);
assert(max(abs(residual))<1e-9,'DynareFirstOrder:DynamicResidual', ...
    'Dynamic steady-state residual is %.3g.',max(abs(residual)));

jacfun=str2func([fname '.dynamic_g1']); % dynamic_g1 is Dynare’s generated first-derivative function
jacobian=jacfun(y,x,M_.params,oo_.steady_state, ...
    M_.dynamic_g1_sparse_rowval,M_.dynamic_g1_sparse_colval, ...
    M_.dynamic_g1_sparse_colptr,T_order,T);
matrices=unpack_dynare_71_jacobian(jacobian,M_);

eqnames=arrayfun(@(j) sprintf('equation_%d',j),1:M_.eq_nbr, ...
    'UniformOutput',false);
if isfield(M_,'equations_tags') && ~isempty(M_.equations_tags)
    tags=M_.equations_tags;
    for j=1:size(tags,1)
        if strcmp(tags{j,2},'name')
            eqnames{tags{j,1}}=tags{j,3};
        end
    end
end
calibration=struct();
for j=1:numel(M_.param_names)
    calibration.(M_.param_names{j})=M_.params(j);
end
verify_parameter_overrides(calibration,parameter_overrides);

model=struct('name',fname,'backend','dynare-7.1-first-order', ...
    'variable_names',{M_.endo_names(:).'}, ...
    'shock_names',{M_.exo_names(:).'},'equation_names',{eqnames}, ...
    'current',matrices.current,'lag',matrices.lag, ...
    'lead',matrices.lead,'shock',matrices.shock, ...
    'calibration',calibration);
model.normalization=struct('coordinate','additive_deviation', ...
    'scale',ones(M_.endo_nbr,1));
model.re=struct('source','dynare','decision_rule',oo_.dr, ...
    'steady_state',oo_.steady_state,'shock_covariance',M_.Sigma_e, ...
    'irfs',getfield_default(oo_,'irfs',struct()));
if keep_generated_files
    work_directory=string(work);
else
    work_directory="";
end
model.dynare=struct('version',runtime.version, ...
    'original_endo_nbr',M_.orig_endo_nbr, ...
    'auxiliary_variables',getfield_default(M_,'aux_vars',struct([])), ...
    'lead_lag_incidence',M_.lead_lag_incidence, ...
    'jacobian_layout','dense-lag-current-lead-shock', ...
    'parameter_overrides',parameter_overrides, ...
    'work_directory',work_directory);
validate_canonical_model(model);
end

function value = getfield_default(s,name,default)
if isfield(s,name), value=s.(name); else, value=default; end
end

function remove_work_directory(work,keep_generated_files)
if keep_generated_files || ~isfolder(work)
    return
end
[removed,message]=rmdir(work,'s');
if ~removed
    warning('DynareFirstOrder:TemporaryCleanup', ...
        'Could not remove temporary Dynare directory %s: %s',work,message);
end
end

function validate_parameter_overrides(overrides)
names=fieldnames(overrides);
for j=1:numel(names)
    value=overrides.(names{j});
    assert(isvarname(names{j}) && isnumeric(value) && isscalar(value) && ...
        isreal(value) && isfinite(value), ...
        'DynareFirstOrder:InvalidParameterOverride', ...
        'Every parameter override must have a valid name and finite real scalar value.');
end
end

function command = make_dynare_command(fname,overrides)
dynare_options={'noclearall','nolog'};
names=fieldnames(overrides);
for j=1:numel(names)
    dynare_options{end+1}=sprintf('-D%s=%.17g', ...
        names{j},overrides.(names{j})); %#ok<AGROW>
end
command=sprintf('dynare %s %s',fname,strjoin(dynare_options,' '));
end

function verify_parameter_overrides(calibration,overrides)
names=fieldnames(overrides);
for j=1:numel(names)
    name=names{j};
    assert(isfield(calibration,name),'DynareFirstOrder:UnknownParameterOverride', ...
        'Dynare model has no parameter named %s.',name);
    tolerance=10*eps(max(1,abs(overrides.(name))));
    assert(abs(calibration.(name)-overrides.(name))<=tolerance, ...
        'DynareFirstOrder:UnusedParameterOverride', ...
        'Parameter override %s was not applied by the Dynare model.',name);
end
end
