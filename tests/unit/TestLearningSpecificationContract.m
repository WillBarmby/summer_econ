classdef TestLearningSpecificationContract < matlab.unittest.TestCase
    %% TESTLEARNINGSPECIFICATIONCONTRACT Define intrinsic learning input.

    methods (Test)
        function acceptsCanonicalSpecification(testCase)
            specification = testsupport.scalar_learning_specification();
            testCase.verifyWarningFree(@() ...
                validate_learning_specification(specification));
        end

        function rejectsNonscalarOrMissingFields(testCase)
            specification = testsupport.scalar_learning_specification();
            testCase.verifyError(@() validate_learning_specification( ...
                [specification specification]), ...
                'AdaptiveLearning:InvalidLearningSpecification');
            specification = rmfield(specification,'expectation_mapping');
            testCase.verifyError(@() ...
                validate_learning_specification(specification), ...
                'AdaptiveLearning:InvalidLearningSpecification');
        end

        function rejectsForbiddenExecutableOrExperimentContent(testCase)
            specification = testsupport.scalar_learning_specification();
            specification.projection = @sin;
            testCase.verifyError(@() ...
                validate_learning_specification(specification), ...
                'AdaptiveLearning:InvalidLearningSpecification');
            specification = testsupport.scalar_learning_specification();
            specification.shocks = zeros(1,2);
            testCase.verifyError(@() ...
                validate_learning_specification(specification), ...
                'AdaptiveLearning:InvalidLearningSpecification');
        end

        function rejectsMalformedLearnedVariables(testCase)
            specification = testsupport.scalar_learning_specification();
            specification.learned_variables = {'y','y'};
            testCase.verifyError(@() ...
                validate_learning_specification(specification), ...
                'AdaptiveLearning:InvalidLearningSpecification');
        end

        function rejectsMalformedRegressorDescriptors(testCase)
            specification = testsupport.scalar_learning_specification();
            specification.regressors{2}.lag = 0;
            testCase.verifyError(@() ...
                validate_learning_specification(specification), ...
                'AdaptiveLearning:InvalidLearningSpecification');
            specification = testsupport.scalar_learning_specification();
            specification.regressors{2}.name = "constant";
            testCase.verifyError(@() ...
                validate_learning_specification(specification), ...
                'AdaptiveLearning:InvalidLearningSpecification');
        end

        function acceptsSupportedGainSchedules(testCase)
            specification = testsupport.scalar_learning_specification();
            specification.gain = struct('type',"constant",'value',0);
            testCase.verifyWarningFree(@() ...
                validate_learning_specification(specification));
            specification.gain = struct('type',"decreasing",'offset',500);
            testCase.verifyWarningFree(@() ...
                validate_learning_specification(specification));
        end

        function rejectsMalformedGainOrEstimator(testCase)
            specification = testsupport.scalar_learning_specification();
            specification.gain.value = -1;
            testCase.verifyError(@() ...
                validate_learning_specification(specification), ...
                'AdaptiveLearning:InvalidLearningSpecification');
            specification = testsupport.scalar_learning_specification();
            specification.estimator.rcond_tolerance = 0;
            testCase.verifyError(@() ...
                validate_learning_specification(specification), ...
                'AdaptiveLearning:InvalidLearningSpecification');
        end

        function rejectsMalformedInitialization(testCase)
            specification = testsupport.scalar_learning_specification();
            specification.initialization.coefficients.scale = Inf;
            testCase.verifyError(@() ...
                validate_learning_specification(specification), ...
                'AdaptiveLearning:InvalidLearningSpecification');
            specification = testsupport.scalar_learning_specification();
            specification.initialization.moments.shock_covariance = -1;
            testCase.verifyError(@() ...
                validate_learning_specification(specification), ...
                'AdaptiveLearning:InvalidLearningSpecification');
        end

        function rejectsMalformedTimingProjectionOrMapping(testCase)
            specification = testsupport.scalar_learning_specification();
            specification.update_timing = "during_decision";
            testCase.verifyError(@() ...
                validate_learning_specification(specification), ...
                'AdaptiveLearning:InvalidLearningSpecification');
            specification = testsupport.scalar_learning_specification();
            specification.projection.limit = 0;
            testCase.verifyError(@() ...
                validate_learning_specification(specification), ...
                'AdaptiveLearning:InvalidLearningSpecification');
            specification = testsupport.scalar_learning_specification();
            specification.expectation_mapping.method = "magic";
            testCase.verifyError(@() ...
                validate_learning_specification(specification), ...
                'AdaptiveLearning:InvalidLearningSpecification');
        end
    end
end
