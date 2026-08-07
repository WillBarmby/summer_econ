classdef TestTrainingIRFComposition < matlab.unittest.TestCase
    %% TESTTRAININGIRFCOMPOSITION Specify composition around RUN_EXPERIMENT.

    methods (Test)
        function trainsThenStartsPairedBranchesFromSameBeliefs(testCase)
            system = adaptive_scalar_system();
            specification = paired_specification();

            result = run_training_irf(system,specification);

            testCase.verifyEqual(result.training.terminal_beliefs.coefficients,1);
            testCase.verifyEqual( ...
                result.baseline.belief_history{1}, ...
                result.training.terminal_beliefs);
            testCase.verifyEqual( ...
                result.shocked.belief_history{1}, ...
                result.training.terminal_beliefs);
            testCase.verifyEqual(result.baseline.path,[1 1 1]);
            testCase.verifyEqual(result.shocked.path,[1 2 4]);
            testCase.verifyEqual(result.irf,[0 1 3]);
            testCase.verifyEqual(result.status,"completed");
            testCase.verifyEmpty(fieldnames(result.termination));
        end

        function leavesCompiledInputUnchanged(testCase)
            system = adaptive_scalar_system();
            original = system.initial_beliefs;

            run_training_irf(system,paired_specification());

            testCase.verifyEqual(system.initial_beliefs,original);
        end

        function restartsBothBranchesFromTerminalTrainingValues(testCase)
            system = adaptive_scalar_system();
            specification = paired_specification();

            result = run_training_irf(system,specification);

            testCase.verifyEqual(result.training.path(:,end),1);
            testCase.verifyEqual(result.baseline.path(:,1),1);
            testCase.verifyEqual(result.shocked.path(:,1),1);
            testCase.verifyEqual(result.irf(:,1),0);
        end

        function stopsCompositionAfterTrainingFailure(testCase)
            system = adaptive_scalar_system();
            specification = paired_specification();
            specification.training.explosion_policy.magnitude_limit = 0.5;

            result = run_training_irf(system,specification);

            testCase.verifyEqual(result.status,"explosive");
            testCase.verifyEqual(result.termination.stage,"training");
            testCase.verifyEmpty(result.baseline);
            testCase.verifyEmpty(result.shocked);
            testCase.verifyEmpty(result.irf);
        end

        function rejectsUnpairedBranchTiming(testCase)
            system = adaptive_scalar_system();
            specification = paired_specification();
            specification.shocked.periods = 1;
            specification.shocked.shocks = 1;

            testCase.verifyError(@() run_training_irf(system,specification), ...
                'AdaptiveLearning:InvalidExperimentSpecification');
        end

        function rejectsUnpairedInitialValues(testCase)
            system = adaptive_scalar_system();
            specification = paired_specification();
            specification.shocked.initial_values = 1;

            testCase.verifyError(@() run_training_irf(system,specification), ...
                'AdaptiveLearning:InvalidExperimentSpecification');
        end
    end
end

function specification = paired_specification()
policy = struct('magnitude_limit',100, ...
    'reject_nonfinite',true,'variable_indices',1);
specification = struct( ...
    'training',struct( ...
        'initial_values',0,'shocks',1,'periods',1, ...
        'explosion_policy',policy,'store_belief_history',false), ...
    'baseline',struct( ...
        'initial_values',0,'shocks',[0 0],'periods',2, ...
        'explosion_policy',policy,'store_belief_history',true), ...
    'shocked',struct( ...
        'initial_values',0,'shocks',[1 0],'periods',2, ...
        'explosion_policy',policy,'store_belief_history',true));
end

function system = adaptive_scalar_system()
system = testsupport.scalar_learning_system();
system.initial_beliefs.coefficients = 0;
system.initial_beliefs.moment_matrix = 1;
system.regressor_names = {'y_lag'};
system.belief_to_plm = @(beliefs) struct( ...
    'intercept',0,'transition',beliefs.coefficients);
system.plm_to_alm = @(plm) struct( ...
    'intercept',0,'transition',plm.transition,'shock',1);
system.regressor = @(path,time) path(:,time-1);
system.outcome = @(path,time) path(:,time);
system.updater = @learn_last_outcome;
end

function [beliefs,diagnostic] = learn_last_outcome(beliefs,~,outcome)
beliefs.coefficients = outcome;
beliefs.observations = beliefs.observations+1;
diagnostic = struct('gain',1,'rcond',1, ...
    'prediction_error',outcome,'projected',false);
end
