classdef TestExperimentEngineAlgebra < matlab.unittest.TestCase
    %% TESTEXPERIMENTENGINEALGEBRA Specify scalar timing and result semantics.

    methods (Test)
        function consumesFullLengthShockSchedule(testCase)
            system = testsupport.scalar_learning_system();
            specification = testsupport.scalar_experiment_specification();

            result = run_experiment(system,specification);

            testCase.verifyEqual(result.path,[0 1 0.5 -0.75], ...
                'AbsTol',1e-12);
            testCase.verifySize(result.path,[1 4]);
            testCase.verifySize(result.plm_history,[1 3]);
            testCase.verifySize(result.alm_history,[1 3]);
            testCase.verifySize(result.diagnostics,[1 3]);
            testCase.verifyEqual(result.status,"completed");
            testCase.verifyEmpty(fieldnames(result.termination));
        end

        function preservesInitialValuesWithZeroPeriods(testCase)
            system = testsupport.scalar_learning_system();
            specification = testsupport.scalar_experiment_specification();
            specification.initial_values = 7;
            specification.shocks = zeros(1,0);
            specification.periods = 0;

            result = run_experiment(system,specification);

            testCase.verifyEqual(result.path,7);
            testCase.verifySize(result.belief_history,[1 1]);
            testCase.verifyEqual(result.belief_history{1}, ...
                system.initial_beliefs);
        end

        function storesInitialAndPostUpdateBeliefs(testCase)
            system = testsupport.scalar_learning_system();
            specification = testsupport.scalar_experiment_specification();

            result = run_experiment(system,specification);

            testCase.verifySize(result.belief_history,[1 4]);
            testCase.verifyEqual(result.belief_history{1}.observations,0);
            testCase.verifyEqual(result.belief_history{2}.observations,1);
            testCase.verifyEqual(result.belief_history{4}.observations,3);
        end

        function omitsBeliefHistoryWhenNotRequested(testCase)
            system = testsupport.scalar_learning_system();
            specification = testsupport.scalar_experiment_specification();
            specification.store_belief_history = false;

            result = run_experiment(system,specification);

            testCase.verifyEmpty(result.belief_history);
        end

        function decidesBeforeUpdatingBeliefs(testCase)
            system = timing_learning_system();
            specification = testsupport.scalar_experiment_specification();
            specification.shocks = [1 0];
            specification.periods = 2;

            result = run_experiment(system,specification);

            testCase.verifyEqual(result.path,[0 1 1]);
            testCase.verifyEqual(result.plm_history{1}.transition,0);
            testCase.verifyEqual(result.plm_history{2}.transition,1);
        end

        function returnsStructuredExplosionTermination(testCase)
            system = fixed_transition_system(2);
            specification = testsupport.scalar_experiment_specification();
            specification.initial_values = 1;
            specification.shocks = zeros(1,3);
            specification.explosion_policy.magnitude_limit = 1.5;

            result = run_experiment(system,specification);

            testCase.verifyEqual(result.status,"explosive");
            testCase.verifyEqual(result.path,[1 2 NaN NaN]);
            testCase.verifyEqual(result.termination.period,1);
            testCase.verifyEqual(result.termination.criterion, ...
                "magnitude_limit");
            testCase.verifyEqual(result.termination.variable_index,1);
            testCase.verifyEqual(result.termination.variable_name,"y");
            testCase.verifyEqual(result.termination.value,2);
        end

        function returnsStructuredInvalidALMTermination(testCase)
            system = fixed_transition_system(0.5);
            system.plm_to_alm = @singular_alm;
            specification = testsupport.scalar_experiment_specification();

            result = run_experiment(system,specification);

            testCase.verifyEqual(result.status,"invalid");
            testCase.verifyEqual(result.path,[0 NaN NaN NaN]);
            testCase.verifyEqual(result.termination.period,1);
            testCase.verifyEqual(result.termination.criterion,"singular_alm");
        end

        function rethrowsUnexpectedRuntimeErrors(testCase)
            system = fixed_transition_system(0.5);
            system.plm_to_alm = @programming_error;
            specification = testsupport.scalar_experiment_specification();

            testCase.verifyError(@() run_experiment(system,specification), ...
                'Test:ProgrammingError');
        end
    end
end

function system = timing_learning_system()
system = fixed_transition_system(0);
system.belief_to_plm = @(beliefs) struct( ...
    'intercept',0,'transition',beliefs.coefficients);
system.plm_to_alm = @(plm) struct( ...
    'intercept',0,'transition',plm.transition,'shock',1);
system.updater = @set_transition_to_outcome;
end

function [beliefs,diagnostic] = set_transition_to_outcome(beliefs,~,outcome)
beliefs.coefficients = outcome;
beliefs.observations = beliefs.observations+1;
diagnostic = struct('gain',1,'rcond',1, ...
    'prediction_error',outcome,'projected',false);
end

function system = fixed_transition_system(transition)
system = testsupport.scalar_learning_system();
system.initial_beliefs.coefficients = transition;
system.initial_beliefs.moment_matrix = 1;
system.regressor_names = {'y_lag'};
system.belief_to_plm = @(~) struct( ...
    'intercept',0,'transition',transition);
system.plm_to_alm = @(~) struct( ...
    'intercept',0,'transition',transition,'shock',0);
system.regressor = @(path,time) path(:,time-1);
system.outcome = @(path,time) path(:,time);
end

function value = singular_alm(~)
error('AdaptiveLearning:SingularALM','Expected numerical failure.');
value = []; %#ok<UNRCH>
end

function value = programming_error(~)
error('Test:ProgrammingError','Unexpected implementation failure.');
value = []; %#ok<UNRCH>
end
