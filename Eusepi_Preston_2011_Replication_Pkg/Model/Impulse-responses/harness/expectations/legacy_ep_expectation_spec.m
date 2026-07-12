function formulation = legacy_ep_expectation_spec(model, kind)
%% LEGACY_EP_EXPECTATION_SPEC Explicit EE/IH formulation for E&P.

if nargin ~= 2
    error('Expectations:RequiredFormulation', ...
        'The model and expectations formulation are both required.');
end
n = numel(model.variable_names);
formulation = struct('name',['E&P ' upper(kind)],'kind',upper(kind), ...
    'variable_names',{model.variable_names},'blocks',[]);
switch upper(kind)
    case 'EE'
        blocks = repmat(make_expectation_spec('',zeros(1,n),1,1),n,1);
        for j = 1:n
            target = zeros(1,n); target(j) = 1;
            blocks(j) = make_expectation_spec(['one_step_' model.variable_names{j}],target,1,1);
        end
    case 'IH'
        beta = model.discounts(1);
        targets = {'rk','wage','gamma_x'};
        blocks = repmat(make_expectation_spec('',zeros(1,n),[1 Inf],beta),numel(targets),1);
        for j = 1:numel(targets)
            target = zeros(1,n);
            target(strcmp(model.variable_names,targets{j})) = 1/beta;
            blocks(j) = make_expectation_spec(['discounted_' targets{j}],target,[1 Inf],beta);
        end
    otherwise
        error('Unknown E&P expectations formulation: %s', kind);
end
formulation.blocks = blocks;
end
