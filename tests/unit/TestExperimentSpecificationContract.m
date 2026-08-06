classdef TestExperimentSpecificationContract < matlab.unittest.TestCase
    %% TESTEXPERIMENTSPECIFICATIONCONTRACT Define one run's input boundary.

    methods (Test)
        function acceptsFullLengthShockSchedule(testCase)
            specification = testsupport.scalar_experiment_specification();
            testCase.verifyWarningFree(@() ...
                validate_experiment_specification(specification));
        end

        function rejectsNonfiniteInitialValues(testCase)
            specification = testsupport.scalar_experiment_specification();
            specification.initial_values = NaN;
            testCase.verifyError(@() ...
                validate_experiment_specification(specification), ...
                'AdaptiveLearning:InvalidExperimentSpecification');
        end

        function rejectsNegativeOrNonintegerPeriods(testCase)
            specification = testsupport.scalar_experiment_specification();
            specification.periods = -1;
            testCase.verifyError(@() ...
                validate_experiment_specification(specification), ...
                'AdaptiveLearning:InvalidExperimentSpecification');

            specification.periods = 1.5;
            testCase.verifyError(@() ...
                validate_experiment_specification(specification), ...
                'AdaptiveLearning:InvalidExperimentSpecification');
        end

        function rejectsShockColumnMismatch(testCase)
            specification = testsupport.scalar_experiment_specification();
            specification.shocks = [1 0];
            testCase.verifyError(@() ...
                validate_experiment_specification(specification), ...
                'AdaptiveLearning:InvalidShockSchedule');
        end

        function rejectsMalformedShockMatrix(testCase)
            specification = testsupport.scalar_experiment_specification();
            specification.shocks = [1 NaN -1];
            testCase.verifyError(@() ...
                validate_experiment_specification(specification), ...
                'AdaptiveLearning:InvalidExperimentSpecification');
        end

        function rejectsUnexpectedSpecificationFields(testCase)
            specification = testsupport.scalar_experiment_specification();
            specification.output_path = "result.mat";
            testCase.verifyError(@() ...
                validate_experiment_specification(specification), ...
                'AdaptiveLearning:InvalidExperimentSpecification');
        end

        function rejectsInvalidInitialDimensionAtRunnerBoundary(testCase)
            learning_system = testsupport.scalar_learning_system();
            specification = testsupport.scalar_experiment_specification();
            specification.initial_values = [0;0];
            testCase.verifyError(@() run_experiment( ...
                learning_system,specification), ...
                'AdaptiveLearning:InvalidExperimentSpecification');
        end

        function rejectsInvalidMonitoredIndexAtRunnerBoundary(testCase)
            learning_system = testsupport.scalar_learning_system();
            specification = testsupport.scalar_experiment_specification();
            specification.explosion_policy.variable_indices = 2;
            testCase.verifyError(@() run_experiment( ...
                learning_system,specification), ...
                'AdaptiveLearning:InvalidExperimentSpecification');
        end

        function rejectsInvalidExplosionPolicy(testCase)
            specification = testsupport.scalar_experiment_specification();
            specification.explosion_policy.magnitude_limit = 0;
            testCase.verifyError(@() ...
                validate_experiment_specification(specification), ...
                'AdaptiveLearning:InvalidExperimentSpecification');

            specification = testsupport.scalar_experiment_specification();
            specification.explosion_policy.variable_indices = 0;
            testCase.verifyError(@() ...
                validate_experiment_specification(specification), ...
                'AdaptiveLearning:InvalidExperimentSpecification');
        end

        function rejectsNonlogicalHistoryFlag(testCase)
            specification = testsupport.scalar_experiment_specification();
            specification.store_belief_history = 1;
            testCase.verifyError(@() ...
                validate_experiment_specification(specification), ...
                'AdaptiveLearning:InvalidExperimentSpecification');
        end

        function rejectsShockDimensionAtRunnerBoundary(testCase)
            learning_system = testsupport.scalar_learning_system();
            specification = testsupport.scalar_experiment_specification();
            specification.shocks = [1 0 -1; 0 0 0];
            testCase.verifyError(@() run_experiment( ...
                learning_system,specification), ...
                'AdaptiveLearning:InvalidShockSchedule');
        end
    end
end
