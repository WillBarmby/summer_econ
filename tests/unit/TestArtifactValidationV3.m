classdef TestArtifactValidationV3 < matlab.unittest.TestCase
    methods (Test)
        function acceptsEveryReusableKind(testCase)
            [result,training,irf]=artifacts();
            testCase.verifyWarningFree(@() validate_artifact(training));
            testCase.verifyWarningFree(@() validate_artifact(irf));
            testCase.verifyWarningFree(@() validate_artifact(result));
        end
        function rejectsUnsupportedSchema(testCase)
            [result,~,~]=artifacts(); result.schema_version="2.0";
            testCase.verifyError(@() validate_artifact(result), ...
                'AdaptiveLearning:UnsupportedArtifactSchema');
        end
        function rejectsDimensionMismatch(testCase)
            [~,~,irf]=artifacts(); irf.reported_irf=[irf.reported_irf 0];
            testCase.verifyError(@() validate_artifact(irf), ...
                'AdaptiveLearning:InvalidArtifact');
        end
        function rejectsExecutableLeakage(testCase)
            [~,training,~]=artifacts(); training.provenance.callback=@sin;
            testCase.verifyError(@() validate_artifact(training), ...
                'AdaptiveLearning:InvalidArtifact');
        end
        function rejectsInconsistentStatus(testCase)
            [~,training,~]=artifacts(); training.status="invalid";
            testCase.verifyError(@() validate_artifact(training), ...
                'AdaptiveLearning:InvalidArtifact');
        end
    end
end
function [result,training,irf]=artifacts()
prepared=scalar_prepared(); options=learning_irf_options(); options.draw_count=1;
options.training_periods=1; options.irf_periods=2; design=learning_irf_design(options);
design.training.shock_name="eps"; design.irf.shock_name="eps";
design.training.standardized_innovations=0; design.irf.standardized_innovations=[0 0];
design.training.innovation_fingerprint=innovation_fingerprint(0);
design.irf.innovation_fingerprint=innovation_fingerprint([0 0]);
training=train_case(prepared,design.training); irf=run_irf(prepared,training,design.irf);
result=run_case(prepared,design);
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
