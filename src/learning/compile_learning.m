function learning_system = compile_learning( ...
    structural_model,re_solution,learning_specification)
%% COMPILE_LEARNING Compile declarative beliefs into executable machinery.
% This boundary resolves public names and combines structural equations with
% an RE baseline. V1 supports one-step expectations and RLS; experiment
% shocks, paths, output locations, and reporting remain downstream.

validate_structural_model(structural_model);
validate_re_solution(re_solution);
validate_learning_specification(learning_specification);

contract = resolve_learning_contract( ...
    structural_model,re_solution,learning_specification);
initial_beliefs = initialize_learning_beliefs( ...
    re_solution,learning_specification,contract);

learning_system = assemble_one_step_learning_system( ...
    structural_model,re_solution,learning_specification, ...
    contract,initial_beliefs);
validate_learning_system(learning_system);
end
