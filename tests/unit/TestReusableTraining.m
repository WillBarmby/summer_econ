classdef TestReusableTraining < matlab.unittest.TestCase
    methods (Test)
        function exposesReusableTerminalHandoff(testCase)
            prepared = scalar_prepared_case();
            design = one_draw_design();
            training = train_case(prepared,design.training);
            testCase.verifyEqual(training.kind,"training");
            testCase.verifyEqual(training.status,"completed");
            testCase.verifyEqual(training.terminal.values,training.simulation_result.path(:,end));
            testCase.verifyEqual(training.terminal.beliefs, ...
                training.simulation_result.terminal_beliefs);
        end
        function evaluatesSeveralIRFsWithoutRetraining(testCase)
            prepared = scalar_prepared_case(); design = one_draw_design();
            training = train_case(prepared,design.training);
            first = run_irf(prepared,training,design.irf);
            second_design = design.irf; second_design.impulse = 2;
            second = run_irf(prepared,training,second_design);
            testCase.verifyEqual(first.training_reference.terminal,training.terminal);
            testCase.verifyEqual(second.native_irf,2*first.native_irf,'AbsTol',1e-12);
            testCase.verifyEqual(first.native_irf,[1 0.5]);
        end
        function wrapperKeepsTrainingAndIRFSeparate(testCase)
            result = run_case(scalar_prepared_case(),one_draw_design());
            testCase.verifyEqual(result.kind,"training_irf");
            testCase.verifyEqual(result.training.kind,"training");
            testCase.verifyEqual(result.irf.kind,"irf");
        end
        function rejectsTrainingFromDifferentCase(testCase)
            prepared = scalar_prepared_case(); design = one_draw_design();
            training = train_case(prepared,design.training);
            prepared.id = "different";
            testCase.verifyError(@() run_irf(prepared,training,design.irf), ...
                'AdaptiveLearning:IncompatibleHandoff');
        end
    end
end

function design = one_draw_design()
options = learning_irf_options(); options.draw_count=1;
options.training_periods=1; options.irf_periods=2;
design = learning_irf_design(options);
design.training.shock_name="eps"; design.irf.shock_name="eps";
design.training.standardized_innovations=0;
design.irf.standardized_innovations=[0 0];
design.training.innovation_fingerprint=innovation_fingerprint(0);
design.irf.innovation_fingerprint=innovation_fingerprint([0 0]);
end
function prepared = scalar_prepared_case()
model=testsupport.scalar_structural_model(); model.name="scalar";
model.backend="fixture"; model.source=struct('file',"fixture");
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
