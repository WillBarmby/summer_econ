classdef TestPublicHandoffs < matlab.unittest.TestCase
    %% TESTPUBLICHANDOFFS Define the four public pipeline boundaries.

    methods (Test)
        function loadModelReturnsStructuralModelOnly(testCase)
            root = setup_project();
            model_file = fullfile(root,'tests','fixtures','tiny_linear.mod');
            structural_model = load_model(model_file,struct());
            validate_structural_model(structural_model);
            testCase.verifyFalse(isfield(structural_model,'re'));
            testCase.verifyFalse(isfield(structural_model,'dynare'));
        end

        function missingModelFailsAtModelBoundary(testCase)
            root = setup_project();
            model_file = fullfile(root,'tests','fixtures','missing.mod');
            testCase.verifyError(@() load_model(model_file,struct()), ...
                'AdaptiveLearning:MissingModelFile');
        end

        function solveREReturnsSeparateSolution(testCase)
            structural_model = testsupport.scalar_structural_model();
            re_solution = solve_re(structural_model);
            validate_re_solution(re_solution);
            testCase.verifyEqual(re_solution.variable_names, ...
                structural_model.variable_names);
            testCase.verifyEqual(re_solution.shock_names, ...
                structural_model.shock_names);
        end

        function compileLearningCombinesOnlyLearningInputs(testCase)
            structural_model = testsupport.scalar_structural_model();
            re_solution = testsupport.scalar_re_solution();
            specification = testsupport.scalar_learning_specification();
            learning_system = compile_learning( ...
                structural_model,re_solution,specification);
            validate_learning_system(learning_system);
            testCase.verifyFalse(isfield(learning_system,'shocks'));
            testCase.verifyFalse(isfield(learning_system,'output_path'));
        end

        function runExperimentReturnsSeparatedOutputs(testCase)
            learning_system = testsupport.scalar_learning_system();
            specification = testsupport.scalar_experiment_specification();
            simulation_result = run_experiment(learning_system,specification);
            required = {'path','belief_history','plm_history','alm_history', ...
                'diagnostics','status','termination'};
            testCase.verifyTrue(all(isfield(simulation_result,required)));
            testCase.verifyEqual(size(simulation_result.path),[1 4]);
        end

        function runnerRejectsInvalidShockDimension(testCase)
            learning_system = testsupport.scalar_learning_system();
            specification = testsupport.scalar_experiment_specification();
            specification.shocks = [1 0 -1; 0 0 0];
            testCase.verifyError(@() run_experiment( ...
                learning_system,specification), ...
                'AdaptiveLearning:InvalidShockSchedule');
        end
    end
end
