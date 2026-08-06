classdef TestRESolutionContract < matlab.unittest.TestCase
    %% TESTRESOLUTIONCONTRACT Define the target RE-law handoff.

    methods (Test)
        function acceptsCanonicalRESolution(testCase)
            solution = testsupport.scalar_re_solution();
            testCase.verifyWarningFree(@() validate_re_solution(solution));
        end

        function preservesStructuralDeclarationOrder(testCase)
            model = testsupport.scalar_structural_model();
            solution = testsupport.scalar_re_solution();
            testCase.verifyEqual(solution.variable_names,model.variable_names);
            testCase.verifyEqual(solution.shock_names,model.shock_names);
        end

        function rejectsWrongInterceptDimensions(testCase)
            solution = testsupport.scalar_re_solution();
            solution.intercept = zeros(2,1);
            testCase.verifyError(@() validate_re_solution(solution), ...
                'AdaptiveLearning:InvalidRESolution');
        end

        function rejectsNonsquareTransition(testCase)
            solution = testsupport.scalar_re_solution();
            solution.transition = zeros(1,2);
            testCase.verifyError(@() validate_re_solution(solution), ...
                'AdaptiveLearning:InvalidRESolution');
        end

        function rejectsWrongShockDimensions(testCase)
            solution = testsupport.scalar_re_solution();
            solution.shock = zeros(1,2);
            testCase.verifyError(@() validate_re_solution(solution), ...
                'AdaptiveLearning:InvalidRESolution');
        end

        function rejectsNonfiniteValues(testCase)
            solution = testsupport.scalar_re_solution();
            solution.transition = Inf;
            testCase.verifyError(@() validate_re_solution(solution), ...
                'AdaptiveLearning:InvalidRESolution');
        end

        function rejectsDuplicateOrOutOfRangeStates(testCase)
            solution = testsupport.scalar_re_solution();
            solution.state_indices = [1 1];
            testCase.verifyError(@() validate_re_solution(solution), ...
                'AdaptiveLearning:InvalidRESolution');

            solution.state_indices = 2;
            testCase.verifyError(@() validate_re_solution(solution), ...
                'AdaptiveLearning:InvalidRESolution');
        end

        function rejectsMalformedNames(testCase)
            solution = testsupport.scalar_re_solution();
            solution.variable_names = {'y','extra'};
            testCase.verifyError(@() validate_re_solution(solution), ...
                'AdaptiveLearning:InvalidRESolution');
        end
    end
end
