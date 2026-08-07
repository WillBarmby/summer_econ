classdef TestComparisonConsumers < matlab.unittest.TestCase
    methods (Test)
        function exposesStoredSummaryREAndStatuses(testCase)
            artifact=comparison_fixture(); item=artifact.cases{1};
            testCase.verifyEqual(artifact_summary(item),item.summary);
            testCase.verifyEqual(artifact_re_benchmark(item),item.re_reported_path);
            testCase.verifyEqual(artifact_re_benchmark(item,"native"),item.re_native_path);
            testCase.verifyEqual(artifact_status_counts(item).completed,2);
        end
        function plotsWithoutSaving(testCase)
            artifact=comparison_fixture(); handle=generate_comparison_irf_figure(artifact);
            cleanup=onCleanup(@() close(handle)); %#ok<NASGU>
            testCase.verifyEqual(string(handle.Visible),"off");
            testCase.verifyGreaterThanOrEqual(numel(findobj(handle,'Type','line')),4);
        end
        function rejectsMismatchedSeriesUnits(testCase)
            artifact=comparison_fixture();
            artifact.cases{2}.series.unit="percentage_points";
            testCase.verifyError(@() generate_comparison_irf_figure(artifact), ...
                'AdaptiveLearning:IncompatibleHandoff');
        end
    end
end
function artifact=comparison_fixture()
prepared=scalar_prepared(); options=learning_irf_options(); options.draw_count=2;
options.training_periods=1; options.irf_periods=2; design=learning_irf_design(options);
design.training.shock_name="eps"; design.irf.shock_name="eps";
design.training.standardized_innovations=[0;0];
design.irf.standardized_innovations=[0 0;0 0];
design.training.innovation_fingerprint=innovation_fingerprint([0;0]);
design.irf.innovation_fingerprint=innovation_fingerprint([0 0;0 0]);
design.provenance.innovation_fingerprint=innovation_fingerprint(zeros(2,3));
artifact=run_comparison({prepared,prepared},design);
end
function prepared=scalar_prepared()
model=testsupport.scalar_structural_model(); model.name="scalar"; model.backend="fixture";
model.source=struct('file',"fixture");
series=struct('id',"y",'label',"Y",'unit',"model_units", ...
    'transformation',struct('kind',"native",'variable',"y",'scale',1));
reporting=struct('source',"irf",'series',series,'title',"Scalar", ...
    'x_label',"Period",'y_label',"Deviation");
prepared=struct('id',"scalar",'label',"Scalar",'structural_model',model, ...
    're_solution',testsupport.scalar_re_solution(), ...
    'learning_specification',testsupport.scalar_learning_specification(), ...
    'learning_system',testsupport.scalar_learning_system(), ...
    'reporting_specification',reporting);
end
