classdef TestStudyToolkit < matlab.unittest.TestCase
    %% TESTSTUDYTOOLKIT Specify named shocks, pairing, and compact storage.

    methods (Test)
        function materializesOnlyTheNamedShock(testCase)
            shocks = materialize_named_shocks( ...
                {'technology','policy'},'policy',[1 -2],0.5);
            testCase.verifyEqual(shocks,[0 0;0.5 -1]);
        end

        function rejectsUnknownNamedShock(testCase)
            testCase.verifyError(@() materialize_named_shocks( ...
                {'technology'},'policy',1,1), ...
                'AdaptiveLearning:UnknownShock');
        end

        function designUsesLegacyRowWiseRNG(testCase)
            options = ep_comparison_options();
            options.draw_count = 2;
            options.training_periods = 2;
            options.irf_periods = 1;
            design = ep_comparison_design(options);
            rng(options.random_seed,'twister');
            expected = [randn(1,3);randn(1,3)];
            testCase.verifyEqual(design.standardized_innovations,expected);
        end

        function runsOneCaseWithImpactOnlyInFirstIRFPeriod(testCase)
            prepared = scalar_prepared_case();
            design = scalar_design([0 0 0]);
            artifact = run_case(prepared,design);
            shocked = artifact.experiment_specification.shocked.shocks;
            baseline = artifact.experiment_specification.baseline.shocks;
            testCase.verifyEqual(shocked-baseline,[1 0]);
            testCase.verifyEqual(artifact.native_irf,[1 0.5]);
            testCase.verifyEqual(artifact.timing.horizons,0:1);
            testCase.verifyFalse(contains_callbacks(artifact));
        end

        function comparisonPairsCasesAndCompactsHistories(testCase)
            prepared = scalar_prepared_case();
            design = scalar_design([0 0 0;1 0 0]);
            artifact = run_comparison({prepared,prepared},design);
            testCase.verifyEqual(numel(artifact.cases),2);
            testCase.verifyEqual(artifact.cases{1}.provenance. ...
                innovation_fingerprint,artifact.cases{2}.provenance. ...
                innovation_fingerprint);
            testCase.verifyFalse(isfield(artifact.cases{1},'simulation_result'));
            testCase.verifySize(artifact.cases{1}.learning_draws,[2 1 2]);
            testCase.verifyEqual(artifact.cases{1}.status_counts.completed,2);
        end

        function describesArtifactWithoutInterpretingCallbacks(testCase)
            artifact = run_case(scalar_prepared_case(),scalar_design([0 0 0]));
            description = describe_artifact(artifact);
            testCase.verifyEqual(description.kind,"training_irf");
            testCase.verifyEqual(description.case.id,"scalar");
            testCase.verifyEqual(description.status,"completed");
        end
    end
end

function prepared = scalar_prepared_case()
model = testsupport.scalar_structural_model();
model.name = "scalar";
model.backend = "fixture";
model.source = struct('file',"fixture");
series = struct('name',"y",'variable',"y", ...
    'cumulative_variables',{{}},'scale',1);
reporting = struct('source',"irf",'series',series, ...
    'title',"Scalar",'x_label',"Period",'y_label',"Deviation");
prepared = struct('id',"scalar",'label',"Scalar case", ...
    'structural_model',model,'re_solution',testsupport.scalar_re_solution(), ...
    'learning_specification',testsupport.scalar_learning_specification(), ...
    'learning_system',testsupport.scalar_learning_system(), ...
    'reporting_specification',reporting);
end

function design = scalar_design(innovations)
design = struct('shock_name',"eps", ...
    'standardized_innovations',innovations, ...
    'training_standard_deviation',1,'training_periods',1, ...
    'irf_periods',2,'impulse',1, ...
    'initialization',struct('initial_values',"zeros"), ...
    'explosion_policy',struct('magnitude_limit',100, ...
        'reject_nonfinite',true), ...
    'band_probabilities',[0.25 0.75],'random_seed',1);
end

function result = contains_callbacks(value)
if isa(value,'function_handle')
    result = true;
elseif isstruct(value)
    result = any(arrayfun(@(j) any(cellfun(@contains_callbacks, ...
        struct2cell(value(j)))),1:numel(value)));
elseif iscell(value)
    result = any(cellfun(@contains_callbacks,value));
else
    result = false;
end
end
