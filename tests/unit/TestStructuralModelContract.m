classdef TestStructuralModelContract < matlab.unittest.TestCase
    %% TESTSTRUCTURALMODELCONTRACT Define the target model handoff.

    methods (Test)
        function acceptsCanonicalModel(testCase)
            model = testsupport.scalar_structural_model();
            testCase.verifyWarningFree(@() validate_structural_model(model));
        end

        function rejectsMissingRequiredField(testCase)
            model = testsupport.scalar_structural_model();
            model = rmfield(model,'lead');
            testCase.verifyError(@() validate_structural_model(model), ...
                'AdaptiveLearning:InvalidStructuralModel');
        end

        function rejectsNonsquareEndogenousMatrix(testCase)
            model = testsupport.scalar_structural_model();
            model.current = zeros(1,2);
            testCase.verifyError(@() validate_structural_model(model), ...
                'AdaptiveLearning:InvalidStructuralModel');
        end

        function rejectsWrongShockDimensions(testCase)
            model = testsupport.scalar_structural_model();
            model.shock = zeros(1,2);
            testCase.verifyError(@() validate_structural_model(model), ...
                'AdaptiveLearning:InvalidStructuralModel');
        end

        function rejectsDuplicateNames(testCase)
            model = testsupport.scalar_structural_model();
            model.variable_names = {'y','y'};
            testCase.verifyError(@() validate_structural_model(model), ...
                'AdaptiveLearning:InvalidStructuralModel');
        end

        function rejectsNonfiniteMatrices(testCase)
            model = testsupport.scalar_structural_model();
            model.current = NaN;
            testCase.verifyError(@() validate_structural_model(model), ...
                'AdaptiveLearning:InvalidStructuralModel');
        end

        function rejectsEmbeddedRESolution(testCase)
            model = testsupport.scalar_structural_model();
            model.re = struct('decision_rule',struct());
            testCase.verifyError(@() validate_structural_model(model), ...
                'AdaptiveLearning:InvalidStructuralModel');
        end

        function rejectsLearningAndExperimentLeakage(testCase)
            model = testsupport.scalar_structural_model();
            model.learning = struct();
            model.experiment = struct();
            testCase.verifyError(@() validate_structural_model(model), ...
                'AdaptiveLearning:InvalidStructuralModel');
        end
    end
end
