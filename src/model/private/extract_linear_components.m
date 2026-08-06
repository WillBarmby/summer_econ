function components = extract_linear_components(context)
%% EXTRACT_LINEAR_COMPONENTS Convert Dynare's store into structural pieces.
% For an explicit linear model, a unit perturbation of one dense dynamic
% input recovers the corresponding column of the equation-residual matrix.
% The dense input is [all lags; all current values; all leads], while the
% output columns are restored to declared variable order here.

M = context.M;
oo = context.oo;
residual_function = context.residual_function;

n = M.endo_nbr;
q = M.exo_nbr;
y = zeros(3*n,1);
x = zeros(1,q);
base = residual_function(y,x,M.params,oo.steady_state);
if max(abs(base))>=1e-10
    error('AdaptiveLearning:NonzeroDeviationModel', ...
        'The linear model is not written in zero-deviation form.');
end

incidence = normalize_incidence(M.lead_lag_incidence,n);
phase = cell(3,1);
for p = 1:3
    phase{p} = zeros(n,n);
    for j = 1:n
        if incidence(p,j)>0
            perturbed = y;
            perturbed((p-1)*n+j) = 1;
            phase{p}(:,j) = residual_function(perturbed,x, ...
                M.params,oo.steady_state)-base;
        end
    end
end

shock = zeros(n,q);
for j = 1:q
    perturbed = x;
    perturbed(j) = 1;
    shock(:,j) = residual_function(y,perturbed,M.params, ...
        oo.steady_state)-base;
end

calibration = struct();
for j = 1:numel(M.param_names)
    calibration.(M.param_names{j}) = M.params(j);
end
components = struct( ...
    'current',phase{2}, ...
    'lag',phase{1}, ...
    'lead',phase{3}, ...
    'shock',shock, ...
    'variable_names',{M.endo_names(:).'}, ...
    'shock_names',{M.exo_names(:).'}, ...
    'equation_names',{equation_names(M,n)}, ...
    'calibration',calibration, ...
    'transformation',struct( ...
        'kind',"deviation", ...
        'level_steady_state',oo.steady_state(:), ...
        'deviation_scales',ones(n,1)));
end

function incidence = normalize_incidence(raw,n)
if size(raw,2)~=n || size(raw,1)>3
    error('AdaptiveLearning:TimingLayout', ...
        'Dynare returned an unsupported timing incidence matrix.');
end
incidence = zeros(3,n);
incidence(1:size(raw,1),:) = raw;
end

function names = equation_names(M,n)
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
