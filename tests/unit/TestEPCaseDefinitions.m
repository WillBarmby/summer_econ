classdef TestEPCaseDefinitions < matlab.unittest.TestCase
    %% TESTEPCASEDEFINITIONS Specify readable E&P configuration values.

    methods (Test)
        function exposesVerifiedDefaults(testCase)
            root = setup_project();
            manifest = testsupport.load_experiment_manifest(fullfile( ...
                root,'experiments','ep_comparison'));
            study_options = learning_irf_options();
            testCase.verifyEqual(manifest.case_definitions{1}.model_options. ...
                parameter_overrides.gamma_bar,exp(0.0053));
            testCase.verifyEqual(study_options.random_seed,20260721);
            testCase.verifyEqual(study_options.draw_count,100);
            testCase.verifyEqual(study_options.training_periods,2000);
            testCase.verifyEqual(study_options.irf_periods,40);
            testCase.verifyEqual(study_options.shock_name,"eps_x");
        end

        function definesDistinctEEAndIHCases(testCase)
            root = setup_project();
            manifest = testsupport.load_experiment_manifest(fullfile( ...
                root,'experiments','ep_comparison'));
            ee = manifest.case_definitions{1};
            ih = manifest.case_definitions{2};
            testCase.verifyEqual(ee.id,"ep_ee");
            testCase.verifyEqual(ih.id,"ep_ih");
            testCase.verifyNotEqual(ee.model_file,ih.model_file);
            testCase.verifyEqual(ee.reporting_specification, ...
                ih.reporting_specification);
        end

        function preparesAndExposesEveryCoreHandoff(testCase)
            root = setup_project();
            manifest = testsupport.load_experiment_manifest(fullfile( ...
                root,'experiments','ep_comparison'));
            prepared = prepare_case(manifest.case_definitions{1});
            testCase.verifyEqual(prepared.id,"ep_ee");
            testCase.verifyTrue(isfield(prepared,'structural_model'));
            testCase.verifyTrue(isfield(prepared,'re_solution'));
            testCase.verifyTrue(isfield(prepared,'learning_specification'));
            testCase.verifyTrue(isfield(prepared,'learning_system'));
            testCase.verifyEqual(prepared.learning_specification.learned_variables, ...
                {'rk','consumption','capital'});
        end

        function rejectsMalformedDefinitionBeforeLoading(testCase)
            root = setup_project();
            manifest = testsupport.load_experiment_manifest(fullfile( ...
                root,'experiments','ep_comparison'));
            definition = manifest.case_definitions{1};
            definition.id = "";
            testCase.verifyError(@() prepare_case(definition), ...
                'AdaptiveLearning:InvalidCaseDefinition');
        end
    end
end
