classdef TestEPCaseDefinitions < matlab.unittest.TestCase
    %% TESTEPCASEDEFINITIONS Specify readable E&P configuration values.

    methods (Test)
        function exposesVerifiedDefaults(testCase)
            case_options = ep_case_options();
            study_options = learning_irf_options();
            testCase.verifyEqual(case_options.gain,0.002);
            testCase.verifyEqual(study_options.random_seed,20260721);
            testCase.verifyEqual(study_options.draw_count,100);
            testCase.verifyEqual(study_options.training_periods,2000);
            testCase.verifyEqual(study_options.irf_periods,40);
            testCase.verifyEqual(study_options.shock_name,"eps_x");
            testCase.verifyEqual(case_options.gamma_bar,exp(0.0053));
        end

        function definesDistinctEEAndIHCases(testCase)
            options = ep_case_options();
            ee = ep_ee_case(options);
            ih = ep_ih_case(options);
            testCase.verifyEqual(ee.id,"ep_ee");
            testCase.verifyEqual(ih.id,"ep_ih");
            testCase.verifyNotEqual(ee.model_file,ih.model_file);
            testCase.verifyEqual(ee.reporting_specification, ...
                ih.reporting_specification);
        end

        function preparesAndExposesEveryCoreHandoff(testCase)
            prepared = prepare_case(ep_ee_case(ep_case_options()));
            testCase.verifyEqual(prepared.id,"ep_ee");
            testCase.verifyTrue(isfield(prepared,'structural_model'));
            testCase.verifyTrue(isfield(prepared,'re_solution'));
            testCase.verifyTrue(isfield(prepared,'learning_specification'));
            testCase.verifyTrue(isfield(prepared,'learning_system'));
            testCase.verifyEqual(prepared.learning_specification.learned_variables, ...
                {'rk','consumption','capital'});
        end

        function rejectsMalformedDefinitionBeforeLoading(testCase)
            definition = ep_ee_case(ep_case_options());
            definition.id = "";
            testCase.verifyError(@() prepare_case(definition), ...
                'AdaptiveLearning:InvalidCaseDefinition');
        end
    end
end
