function re_solution = solve_re(structural_model)
%% SOLVE_RE Solve a structural model and return a separate RE law.
% The structural model describes equations. The RE solution describes the
% reduced-form law of motion implied by those equations. Dynare is used only
% behind this boundary; its decision rule and global data stores are never
% attached to either public value.

validate_structural_model(structural_model);
source = validate_solver_source(structural_model);

re_solution = run_dynare_model( ...
    source,source.parameter_overrides, ...
    @(context) extract_re_solution(context,structural_model));

validate_re_solution(re_solution);
end
