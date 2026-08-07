classdef TestLearningIRFDesign < matlab.unittest.TestCase
    methods (Test)
        function separatesCaseAndStudyOptions(testCase)
            testCase.verifyFalse(isfield(ep_case_options(),'training_periods'));
            testCase.verifyFalse(isfield(learning_irf_options(),'gain'));
        end
        function generatesSplitRowWiseInnovations(testCase)
            options = learning_irf_options();
            options.draw_count = 2; options.training_periods = 2; options.irf_periods = 1;
            design = learning_irf_design(options);
            rng(options.random_seed,'twister'); expected = [randn(1,3);randn(1,3)];
            testCase.verifyEqual(design.training.standardized_innovations,expected(:,1:2));
            testCase.verifyEqual(design.irf.standardized_innovations,expected(:,3));
            testCase.verifyNotEmpty(design.provenance.innovation_fingerprint);
        end
        function rejectsMalformedOptions(testCase)
            options = learning_irf_options(); options.draw_count = 0;
            testCase.verifyError(@() learning_irf_design(options), ...
                'AdaptiveLearning:InvalidStudyOptions');
        end
    end
end
