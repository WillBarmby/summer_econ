classdef TestNKCaseDefinition < matlab.unittest.TestCase
    %% TESTNKCASEDEFINITION Specify NK EE above the shared nonlinear loader.

    methods (Test)
        function definesTechnologyEEWithoutRunnerDetails(testCase)
            definition = nk_ee_case(nk_case_options());
            testCase.verifyEqual(definition.id,"nk_technology_ee");
            testCase.verifyEqual(definition.model_options.kind,"nonlinear");
            testCase.verifyEqual(definition.model_options.deviation_scales, ...
                struct('gamma_x',0.01));
            testCase.verifyEqual(string({definition.reporting_specification. ...
                series.id}),["output" "consumption" "investment" ...
                "hours" "inflation" "nominal_rate"]);
        end

        function preparesTwoShockLearningContract(testCase)
            prepared = prepare_case(nk_ee_case(nk_case_options()));
            testCase.verifyEqual(prepared.learning_specification. ...
                learned_variables, ...
                {'rk','consumption','capital','inflation','output'});
            covariance = prepared.learning_specification.initialization. ...
                moments.shock_covariance;
            testCase.verifyEqual(size(covariance),[2 2]);
            testCase.verifyEqual(covariance(2,:),[0 0]);
            testCase.verifyEqual(prepared.learning_system.shock_names, ...
                {'eps_x','eps_s'});
        end

        function runsShortTechnologyCaseWithPremiumShockZero(testCase)
            options = learning_irf_options();
            options.draw_count = 1;
            options.training_periods = 8;
            options.irf_periods = 5;
            prepared = prepare_case(nk_ee_case(nk_case_options()));
            artifact = run_case(prepared,learning_irf_design(options));
            testCase.verifyEqual(artifact.status,"completed");
            testCase.verifyEqual(artifact.training.training_design.shocks(2,:), ...
                zeros(1,options.training_periods));
            testCase.verifyEqual(artifact.irf.irf_design.shocked_shocks(2,:), ...
                zeros(1,options.irf_periods));
            testCase.verifySize(artifact.irf.reported_irf,[6 5]);
        end
    end
end
