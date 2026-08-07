function matrices = extract_analytical_jacobian(context,evaluation_state)
%% EXTRACT_ANALYTICAL_JACOBIAN Evaluate Dynare's generated dynamic_g1.

M = context.M;
oo = context.oo;
n = M.endo_nbr;
if ~isnumeric(evaluation_state) || ~isequal(size(evaluation_state),[n 1]) || ...
        ~all(isfinite(evaluation_state))
    error('AdaptiveLearning:InvalidSteadyState', ...
        'Jacobian evaluation requires one finite value per variable.');
end
dynamic_values = repmat(evaluation_state,3,1);
exogenous = oo.exo_steady_state(:).';
residual = context.residual_function( ...
    dynamic_values,exogenous,M.params,evaluation_state);
if max(abs(residual))>=1e-10
    error('AdaptiveLearning:NonzeroSteadyStateResidual', ...
        'Dynamic residual at the evaluation point is %.3g.',max(abs(residual)));
end
jacobian = full(context.jacobian_function( ...
    dynamic_values,exogenous,M.params,evaluation_state, ...
    M.dynamic_g1_sparse_rowval,M.dynamic_g1_sparse_colval, ...
    M.dynamic_g1_sparse_colptr));
matrices = unpack_dynamic_jacobian(jacobian,M);
end
