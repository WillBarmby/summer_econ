classdef TestRESolver < matlab.unittest.TestCase
    %% TESTRESOLVER Exercise the Dynare-to-public-RE handoff.

    methods (Test)
        function solvesTinyModelInDeclarationOrder(testCase)
            structural_model = load_tiny_model();

            re_solution = solve_re(structural_model);

            validate_re_solution(re_solution);
            testCase.verifyEqual(re_solution.intercept,0);
            testCase.verifyEqual(re_solution.transition,2-sqrt(2), ...
                'AbsTol',1e-10);
            testCase.verifyEqual(re_solution.shock,4-2*sqrt(2), ...
                'AbsTol',1e-10);
            testCase.verifyEqual(re_solution.state_indices,1);
            testCase.verifyEqual(re_solution.variable_names,{'y'});
            testCase.verifyEqual(re_solution.shock_names,{'eps'});
        end

        function keepsBackendStateOutOfBothPublicValues(testCase)
            structural_model = load_tiny_model();

            re_solution = solve_re(structural_model);

            testCase.verifyFalse(isfield(structural_model,'re'));
            testCase.verifyFalse(isfield(structural_model,'decision_rule'));
            testCase.verifyFalse(isfield(re_solution,'dynare'));
            testCase.verifyFalse(isfield(re_solution,'decision_rule'));
        end

        function rejectsModelWithoutReproducibleSource(testCase)
            structural_model = testsupport.scalar_structural_model();

            testCase.verifyError(@() solve_re(structural_model), ...
                'AdaptiveLearning:MissingSolverSource');
        end
    end
end

function structural_model = load_tiny_model()
test_directory = fileparts(mfilename('fullpath'));
model_file = fullfile(fileparts(test_directory), ...
    'fixtures','tiny_linear.mod');
structural_model = load_model(model_file,struct('kind',"linear"));
end
