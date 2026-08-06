classdef TestModelLoader < matlab.unittest.TestCase
    %% TESTMODELLOADER Define the model-file boundary.

    methods (Test)
        function loadsTinyLinearModelAsStructuralModel(testCase)
            root = setup_project();
            model_file = fullfile(root,'tests','fixtures','tiny_linear.mod');
            model_options = struct('kind',"linear");

            structural_model = load_model(model_file,model_options);

            validate_structural_model(structural_model);
            testCase.verifyEqual(structural_model.variable_names,{'y'});
            testCase.verifyEqual(structural_model.shock_names,{'eps'});
            testCase.verifyEqual(structural_model.equation_names, ...
                {'y'});
            testCase.verifyEqual(structural_model.current,1);
            testCase.verifyEqual(structural_model.lag,-0.5);
            testCase.verifyEqual(structural_model.lead,-0.25);
            testCase.verifyEqual(structural_model.shock,-1);
            testCase.verifyFalse(isfield(structural_model,'re'));
            testCase.verifyFalse(isfield(structural_model,'dynare'));
        end
    end
end
