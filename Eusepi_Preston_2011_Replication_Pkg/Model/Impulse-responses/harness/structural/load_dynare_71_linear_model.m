function model = load_dynare_71_linear_model(mod_path)
%% LOAD_DYNARE_71_LINEAR_MODEL Load an explicitly linear deviation-form model.

runtime = configure_dynare_71();
assert(isfile(mod_path),'Dynare model not found: %s',mod_path);
source = fileread(mod_path);
assert(~isempty(regexp(source,'model\s*\([^;)]*linear[^;)]*\)\s*;','once')), ...
    ['Only .mod files explicitly declared model(linear) and written in ' ...
     'deviations from steady state are supported.']);
work = tempname; mkdir(work);
[~,fname,ext] = fileparts(mod_path);
copyfile(mod_path,fullfile(work,[fname ext]));
old = pwd; cleanup = onCleanup(@() cd(old));
cd(work);
evalin('base',sprintf('dynare %s noclearall nolog',fname));
global M_ oo_
assert(strcmp(M_.fname,fname));
n = M_.endo_nbr; q = M_.exo_nbr;
incidence = M_.lead_lag_incidence;
% Dynare 7.1 generated residual functions use the dense layout
% [y(-1); y; y(+1)], while lead_lag_incidence indicates active entries.
y = zeros(3*n,1); x = zeros(1,q);
residfun = str2func([fname '.dynamic_resid']);
base = residfun(y,x,M_.params,oo_.steady_state);
assert(max(abs(base)) < 1e-10, ...
    'Model is not a zero-deviation linear system; residual %.3g.',max(abs(base)));
phase = cell(3,1);
for p = 1:3
    phase{p} = zeros(n,n);
    for j = 1:n
        if incidence(p,j) > 0
            y1 = y; y1((p-1)*n+j) = 1;
            phase{p}(:,j) = residfun(y1,x,M_.params,oo_.steady_state)-base;
        end
    end
end
shock = zeros(n,q);
for j = 1:q
    x1 = x; x1(j) = 1;
    shock(:,j) = residfun(y,x1,M_.params,oo_.steady_state)-base;
end
eqnames = arrayfun(@(j) sprintf('equation_%d',j),1:n,'UniformOutput',false);
if isfield(M_,'equations_tags') && ~isempty(M_.equations_tags)
    tags = M_.equations_tags;
    for j = 1:size(tags,1)
        if strcmp(tags{j,2},'name')
            eqnames{tags{j,1}} = tags{j,3};
        end
    end
end
calibration = struct();
for j = 1:numel(M_.param_names)
    calibration.(M_.param_names{j}) = M_.params(j);
end
model = struct('name',fname,'backend','dynare-7.1', ...
    'variable_names',{M_.endo_names(:).'},'shock_names',{M_.exo_names(:).'}, ...
    'equation_names',{eqnames},'current',phase{2},'lag',phase{1}, ...
    'lead',phase{3},'shock',shock,'calibration',calibration);
model.re = struct('source','dynare','decision_rule',oo_.dr, ...
    'steady_state',oo_.steady_state,'irfs',getfield_default(oo_,'irfs',struct()));
model.dynare = struct('version',runtime.version,'var',getfield_default(M_,'var',struct()), ...
    'var_expectation',getfield_default(M_,'var_expectation',struct()), ...
    'work_directory',work);
validate_canonical_model(model);
end

function value = getfield_default(s,name,default)
if isfield(s,name), value = s.(name); else, value = default; end
end
