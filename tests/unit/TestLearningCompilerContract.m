classdef TestLearningCompilerContract < matlab.unittest.TestCase
    %% TESTLEARNINGCOMPILERCONTRACT Define the learning handoff.

    methods (Test)
        function acceptsCompiledLearningSystem(testCase)
            system = testsupport.scalar_learning_system();
            testCase.verifyWarningFree(@() validate_learning_system(system));
        end

        function rejectsMissingLearningCallback(testCase)
            system = testsupport.scalar_learning_system();
            system = rmfield(system,'updater');
            testCase.verifyError(@() validate_learning_system(system), ...
                'AdaptiveLearning:InvalidLearningSystem');
        end

        function rejectsNonfunctionLearningCallback(testCase)
            system = testsupport.scalar_learning_system();
            system.outcome = 0;
            testCase.verifyError(@() validate_learning_system(system), ...
                'AdaptiveLearning:InvalidLearningSystem');
        end

        function rejectsMalformedInitialBeliefs(testCase)
            system = testsupport.scalar_learning_system();
            system.initial_beliefs = [];
            testCase.verifyError(@() validate_learning_system(system), ...
                'AdaptiveLearning:InvalidLearningSystem');
        end

        function compilesMinimalDeclarativeSpecification(testCase)
            model = testsupport.scalar_structural_model();
            solution = testsupport.scalar_re_solution();
            specification = testsupport.scalar_learning_specification();
            testCase.verifyWarningFree(@() compile_learning( ...
                model,solution,specification));
        end

        function rejectsUnknownLearnedVariable(testCase)
            model = testsupport.scalar_structural_model();
            solution = testsupport.scalar_re_solution();
            specification = testsupport.scalar_learning_specification();
            specification.learned_variables = {'unknown'};
            testCase.verifyError(@() compile_learning( ...
                model,solution,specification), ...
                'AdaptiveLearning:UnknownVariable');
        end

        function rejectsDuplicateLearnedVariable(testCase)
            model = testsupport.scalar_structural_model();
            solution = testsupport.scalar_re_solution();
            specification = testsupport.scalar_learning_specification();
            specification.learned_variables = {'y','y'};
            testCase.verifyError(@() compile_learning( ...
                model,solution,specification), ...
                'AdaptiveLearning:InvalidLearningSpecification');
        end

        function rejectsMissingSpecificationField(testCase)
            model = testsupport.scalar_structural_model();
            solution = testsupport.scalar_re_solution();
            specification = rmfield( ...
                testsupport.scalar_learning_specification(),'gain');
            testCase.verifyError(@() compile_learning( ...
                model,solution,specification), ...
                'AdaptiveLearning:InvalidLearningSpecification');
        end

        function rejectsInvalidGain(testCase)
            model = testsupport.scalar_structural_model();
            solution = testsupport.scalar_re_solution();
            specification = testsupport.scalar_learning_specification();
            specification.gain.value = -1;
            testCase.verifyError(@() compile_learning( ...
                model,solution,specification), ...
                'AdaptiveLearning:InvalidLearningSpecification');
        end

        function rejectsExecutableSpecificationContent(testCase)
            model = testsupport.scalar_structural_model();
            solution = testsupport.scalar_re_solution();
            specification = testsupport.scalar_learning_specification();
            specification.regressors = @regressor_closure;
            testCase.verifyError(@() compile_learning( ...
                model,solution,specification), ...
                'AdaptiveLearning:InvalidLearningSpecification');
        end

        function rejectsInvalidUpdateTiming(testCase)
            model = testsupport.scalar_structural_model();
            solution = testsupport.scalar_re_solution();
            specification = testsupport.scalar_learning_specification();
            specification.update_timing = 'during_decision';
            testCase.verifyError(@() compile_learning( ...
                model,solution,specification), ...
                'AdaptiveLearning:InvalidLearningSpecification');
        end

        function rejectsEmptyLearnedVariableSet(testCase)
            model = testsupport.scalar_structural_model();
            solution = testsupport.scalar_re_solution();
            specification = testsupport.scalar_learning_specification();
            specification.learned_variables = {};
            testCase.verifyError(@() compile_learning( ...
                model,solution,specification), ...
                'AdaptiveLearning:InvalidLearningSpecification');
        end
    end
end

function value = regressor_closure(~)
value = 0;
end
