classdef TestNKLegacyParity < matlab.unittest.TestCase
    %% TESTNKLEGACYPARITY Match a small independently generated main run.

    methods (Test)
        function matchesOneDrawTechnologyExperiment(testCase)
            root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            frozen = load(fullfile(root,'tests','fixtures', ...
                'nk_small_reference.mat'),'reference');
            reference = frozen.reference;
            options = ep_comparison_options();
            options.draw_count = reference.config.draw_count;
            options.training_periods = reference.config.training_periods;
            options.irf_periods = reference.config.ir_periods;
            design = ep_comparison_design(options);
            artifact = run_case(prepare_case(nk_ee_case(options)),design);

            testCase.verifyEqual(design.standardized_innovations, ...
                reference.standardized_innovations);
            testCase.verifyEqual(artifact.simulation_result.status, ...
                reference.status);
            verify_close(testCase,artifact.re_native_path, ...
                reference.re_native_path,"RE native path");
            verify_close(testCase,artifact.re_reported_path, ...
                reference.re_reported_path,"RE reported path");
            verify_close(testCase,artifact.reported_irf, ...
                reference.learning_reported_irf,"learning reported IRF");
            beliefs = artifact.simulation_result.training.terminal_beliefs;
            verify_close(testCase,beliefs.coefficients, ...
                reference.terminal_coefficients,"terminal coefficients");
            verify_close(testCase,beliefs.moment_matrix, ...
                reference.terminal_moments,"terminal moments");
            testCase.verifyEqual(beliefs.projection_events, ...
                reference.projection_events);
        end
    end
end

function verify_close(testCase,actual,expected,handoff)
error_value = max(abs(actual-expected),[],'all');
testCase.verifyLessThanOrEqual(error_value,1e-10,sprintf( ...
    '%s differs from main by %.17g.',handoff,error_value));
end
