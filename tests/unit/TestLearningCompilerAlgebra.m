classdef TestLearningCompilerAlgebra < matlab.unittest.TestCase
    %% TESTLEARNINGCOMPILERALGEBRA Specify exact one-step compiler behavior.

    methods (Test)
        function compilesTinyDynareModelEndToEnd(testCase)
            root = setup_project();
            model_file = fullfile(root,'tests','fixtures','tiny_linear.mod');
            model = load_model(model_file,struct('kind',"linear"));
            solution = solve_re(model);
            specification = testsupport.scalar_learning_specification();

            system = compile_learning(model,solution,specification);

            validate_learning_system(system);
            expected_variance = solution.shock^2/(1-solution.transition^2);
            testCase.verifyEqual(system.initial_beliefs.coefficients, ...
                [solution.intercept solution.transition],'AbsTol',1e-10);
            testCase.verifyEqual(system.initial_beliefs.moment_matrix, ...
                diag([1 expected_variance]),'AbsTol',1e-10);
            plm = system.belief_to_plm(system.initial_beliefs);
            alm = system.plm_to_alm(plm);
            testCase.verifyEqual(plm.intercept,solution.intercept, ...
                'AbsTol',1e-10);
            testCase.verifyEqual(plm.transition,solution.transition, ...
                'AbsTol',1e-10);
            testCase.verifyEqual(alm.intercept,solution.intercept, ...
                'AbsTol',1e-10);
            testCase.verifyEqual(alm.transition,solution.transition, ...
                'AbsTol',1e-10);
            testCase.verifyEqual(alm.shock,solution.shock,'AbsTol',1e-10);
        end

        function exposesResolvedNamesAndDimensions(testCase)
            [model,solution,specification] = two_variable_case();

            system = compile_learning(model,solution,specification);

            testCase.verifyEqual(system.variable_names,{'y','z'});
            testCase.verifyEqual(system.shock_names,{'eps'});
            testCase.verifyEqual(system.learned_variables,{'y'});
            testCase.verifyEqual(system.regressor_names, ...
                {'constant','y_lag'});
            testCase.verifySize(system.initial_beliefs.coefficients,[1 2]);
            testCase.verifySize(system.initial_beliefs.moment_matrix,[2 2]);
        end

        function initializesExactScaledREBeliefsAndMoments(testCase)
            [model,solution,specification] = two_variable_case();
            specification.initialization.coefficients.scale = 0.5;

            system = compile_learning(model,solution,specification);

            testCase.verifyEqual(system.initial_beliefs.coefficients,[0 0.25]);
            testCase.verifyEqual(system.initial_beliefs.moment_matrix, ...
                diag([1 4/3]),'AbsTol',1e-12);
            testCase.verifyEqual(system.initial_beliefs.observations,0);
            testCase.verifyEqual(system.initial_beliefs.projection_events,0);
            testCase.verifyFalse(system.initial_beliefs.invalid);
        end

        function replacesOnlyLearnedPLMCoefficients(testCase)
            [model,solution,specification] = two_variable_case();
            system = compile_learning(model,solution,specification);
            beliefs = system.initial_beliefs;
            beliefs.coefficients = [1 0.8];

            plm = system.belief_to_plm(beliefs);

            testCase.verifyEqual(plm.intercept,[1;0]);
            testCase.verifyEqual(plm.transition,[0.8 0;0 0.25]);
        end

        function convertsPLMToExactOneStepALM(testCase)
            [model,solution,specification] = two_variable_case();
            system = compile_learning(model,solution,specification);
            plm = struct('intercept',[1;0], ...
                'transition',[0.8 0;0 0.25]);

            alm = system.plm_to_alm(plm);

            lhs = model.current+model.lead*plm.transition;
            testCase.verifyEqual(alm.intercept, ...
                -(lhs\(model.lead*plm.intercept)),'AbsTol',1e-12);
            testCase.verifyEqual(alm.transition,-(lhs\model.lag), ...
                'AbsTol',1e-12);
            testCase.verifyEqual(alm.shock,-(lhs\model.shock), ...
                'AbsTol',1e-12);
        end

        function compilesRegressorOutcomeAndProjection(testCase)
            [model,solution,specification] = two_variable_case();
            system = compile_learning(model,solution,specification);
            path = [2 3;7 11];
            testCase.verifyEqual(system.regressor(path,2),[1;2]);
            testCase.verifyEqual(system.outcome(path,2),3);

            [beliefs,diagnostic] = system.updater( ...
                system.initial_beliefs,[1;1],10);

            testCase.verifyEqual(beliefs.coefficients(2),0.5, ...
                'AbsTol',1e-12);
            testCase.verifyGreaterThan(beliefs.coefficients(1),0);
            testCase.verifyTrue(diagnostic.projected);
            testCase.verifyEqual(beliefs.projection_events,1);
        end

        function zeroGainRecordsObservationWithoutMovingBeliefs(testCase)
            [model,solution,specification] = two_variable_case();
            specification.gain.value = 0;
            system = compile_learning(model,solution,specification);
            initial = system.initial_beliefs;

            [updated,diagnostic] = system.updater(initial,[1;2],99);

            testCase.verifyEqual(updated.coefficients,initial.coefficients);
            testCase.verifyEqual(updated.moment_matrix,initial.moment_matrix);
            testCase.verifyEqual(updated.observations,1);
            testCase.verifyEqual(diagnostic.gain,0);
        end

        function rejectsIncompatibleModelAndRESolution(testCase)
            [model,solution,specification] = two_variable_case();
            solution.variable_names = {'z','y'};

            testCase.verifyError(@() compile_learning( ...
                model,solution,specification), ...
                'AdaptiveLearning:IncompatibleHandoff');
        end

        function rejectsWrongShockCovarianceDimension(testCase)
            [model,solution,specification] = two_variable_case();
            specification.initialization.moments.shock_covariance = eye(2);

            testCase.verifyError(@() compile_learning( ...
                model,solution,specification), ...
                'AdaptiveLearning:IncompatibleHandoff');
        end
    end
end

function [model,solution,specification] = two_variable_case()
transition = diag([0.5 0.25]);
shock = [1;0.5];
lead = diag([-0.1 -0.2]);
lhs = eye(2)+lead*transition;
model = struct( ...
    'current',eye(2), ...
    'lag',-lhs*transition, ...
    'lead',lead, ...
    'shock',-lhs*shock, ...
    'variable_names',{{'y','z'}}, ...
    'shock_names',{{'eps'}}, ...
    'equation_names',{{'y_equation','z_equation'}}, ...
    'calibration',struct(), ...
    'transformation',struct());
solution = struct( ...
    'intercept',zeros(2,1), ...
    'transition',transition, ...
    'shock',shock, ...
    'state_indices',[1 2], ...
    'variable_names',{{'y','z'}}, ...
    'shock_names',{{'eps'}});
specification = testsupport.scalar_learning_specification();
end
