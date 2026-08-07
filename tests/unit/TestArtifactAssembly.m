classdef TestArtifactAssembly < matlab.unittest.TestCase
    %% TESTARTIFACTASSEMBLY Specify a pure reproducibility container.

    methods (Test)
        function assemblesSingleRunWithoutExecutableState(testCase)
            model = testsupport.scalar_structural_model();
            learning = testsupport.scalar_learning_specification();
            experiment = testsupport.scalar_experiment_specification();
            result = run_experiment( ...
                testsupport.scalar_learning_system(),experiment);

            artifact = assemble_artifact(model,learning,experiment,result);

            expected = {'schema_version','kind','case','model', ...
                'learning_specification','experiment_specification', ...
                'simulation_result','axes','units','timing','provenance'};
            testCase.verifyEqual(sort(fieldnames(artifact)),sort(expected.'));
            testCase.verifyEqual(artifact.schema_version,"3.0");
            testCase.verifyEqual(artifact.kind,"single_run");
            testCase.verifyEqual(artifact.model.variable_names,{'y'});
            testCase.verifyEqual(artifact.model.shock_names,{'eps'});
            testCase.verifyEqual(artifact.model.calibration,model.calibration);
            testCase.verifyEqual(artifact.model.transformation, ...
                model.transformation);
            testCase.verifyFalse(isfield(artifact.model,'current'));
            testCase.verifyFalse(isfield(artifact.model,'lead'));
            testCase.verifyFalse(contains_function_handle(artifact));
        end

        function preservesSpecificationsAndRawResult(testCase)
            model = testsupport.scalar_structural_model();
            learning = testsupport.scalar_learning_specification();
            experiment = testsupport.scalar_experiment_specification();
            result = run_experiment( ...
                testsupport.scalar_learning_system(),experiment);

            artifact = assemble_artifact(model,learning,experiment,result);

            testCase.verifyEqual(artifact.learning_specification,learning);
            testCase.verifyEqual(artifact.experiment_specification,experiment);
            testCase.verifyEqual(artifact.simulation_result,result);
        end

        function directsPairedResultsToPublicComposition(testCase)
            model = testsupport.scalar_structural_model();
            learning = testsupport.scalar_learning_specification();
            experiment = paired_specification();
            result = run_training_irf( ...
                adaptive_scalar_system(),experiment);

            testCase.verifyError(@() assemble_artifact( ...
                model,learning,experiment,result), ...
                'AdaptiveLearning:InvalidArtifact');
        end

        function rejectsMalformedResult(testCase)
            model = testsupport.scalar_structural_model();
            learning = testsupport.scalar_learning_specification();
            experiment = testsupport.scalar_experiment_specification();

            testCase.verifyError(@() assemble_artifact( ...
                model,learning,experiment,struct('path',0)), ...
                'AdaptiveLearning:InvalidArtifact');
        end

        function rejectsExecutableExperimentMetadata(testCase)
            model = testsupport.scalar_structural_model();
            learning = testsupport.scalar_learning_specification();
            experiment = struct('runner',@sin);
            result = struct('status',"completed",'termination',struct(), ...
                'path',0);

            testCase.verifyError(@() assemble_artifact( ...
                model,learning,experiment,result), ...
                'AdaptiveLearning:InvalidArtifact');
        end
    end
end

function result = contains_function_handle(value)
if isa(value,'function_handle')
    result = true;
elseif isstruct(value)
    result = any(arrayfun(@(index) any(cellfun( ...
        @contains_function_handle,struct2cell(value(index)))), ...
        1:numel(value)));
elseif iscell(value)
    result = any(cellfun(@contains_function_handle,value));
else
    result = false;
end
end

function specification = paired_specification()
policy = struct('magnitude_limit',100, ...
    'reject_nonfinite',true,'variable_indices',1);
specification = struct( ...
    'training',struct('initial_values',0,'shocks',1,'periods',1, ...
        'explosion_policy',policy,'store_belief_history',false), ...
    'baseline',struct('initial_values',0,'shocks',[0 0],'periods',2, ...
        'explosion_policy',policy,'store_belief_history',true), ...
    'shocked',struct('initial_values',0,'shocks',[1 0],'periods',2, ...
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
