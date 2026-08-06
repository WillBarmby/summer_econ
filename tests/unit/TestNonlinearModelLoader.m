classdef TestNonlinearModelLoader < matlab.unittest.TestCase
    %% TESTNONLINEARMODELLOADER Specify analytical nonlinear handoffs.

    methods (Test)
        function loadsNKThroughCanonicalStructuralContract(testCase)
            model = load_nk(testsupport.nk_model_options());
            expected_variables = {'rk','wage','output','hours','consumption', ...
                'investment','capital','inflation','nominal_rate', ...
                'marginal_cost','risk_premium','gamma_x'};
            expected_equations = {'capital_demand','labor_supply','production', ...
                'labor_demand','capital_euler','resource_constraint', ...
                'capital_accumulation','rotemberg_pricing','bond_euler', ...
                'monetary_policy','technology_growth','risk_premium'};
            validate_structural_model(model);
            testCase.verifyEqual(model.variable_names,expected_variables);
            testCase.verifyEqual(model.equation_names,expected_equations);
            testCase.verifyEqual(model.backend,"dynare-nonlinear-first-order");
            testCase.verifyEqual(model.source.kind,"nonlinear");
            testCase.verifyFalse(isfield(model,'re'));
            testCase.verifyFalse(isfield(model,'dynare'));
        end

        function recordsSteadyStateAndResolvedDeviationScales(testCase)
            model = load_nk(testsupport.nk_model_options());
            steady = model.transformation.level_steady_state;
            scales = model.transformation.deviation_scales;
            gamma = find(strcmp(model.variable_names,'gamma_x'));
            positive = steady>0;
            testCase.verifyEqual(scales(positive),steady(positive)/100, ...
                'AbsTol',1e-12);
            testCase.verifyEqual(scales(gamma),0.01,'AbsTol',1e-12);
            testCase.verifyEqual(model.transformation.scale_overrides, ...
                struct('gamma_x',0.01));
        end

        function requiresScaleForZeroSteadyStateVariable(testCase)
            options = testsupport.nk_model_options();
            options.deviation_scales = struct();
            testCase.verifyError(@() load_nk(options), ...
                'AdaptiveLearning:MissingDeviationScale');
        end

        function rejectsInvalidScaleBeforeCallingDynare(testCase)
            options = testsupport.nk_model_options();
            options.deviation_scales.gamma_x = -1;
            testCase.verifyError(@() load_nk(options), ...
                'AdaptiveLearning:InvalidModelOptions');
        end

        function transformsDynareRELawIntoTheSameUnits(testCase)
            model = load_nk(testsupport.nk_model_options());
            solution = solve_re(model);
            gamma = find(strcmp(model.variable_names,'gamma_x'));
            eps_x = find(strcmp(model.shock_names,'eps_x'));
            eps_s = find(strcmp(model.shock_names,'eps_s'));
            validate_re_solution(solution);
            testCase.verifyEqual(solution.shock(gamma,eps_x),1,'AbsTol',1e-10);
            testCase.verifyEqual(solution.shock(:,eps_s), ...
                zeros(numel(model.variable_names),1),'AbsTol',1e-10);
            plm = struct('intercept',zeros(numel(model.variable_names),1), ...
                'transition',solution.transition);
            alm = plm_to_alm_one_step(model,plm);
            testCase.verifyEqual(alm.transition,solution.transition, ...
                'AbsTol',1e-10);
            testCase.verifyEqual(alm.shock_impact,solution.shock, ...
                'AbsTol',1e-10);
        end

        function appliesParameterOverridesToBothHandoffs(testCase)
            options = testsupport.nk_model_options();
            options.parameter_overrides = struct('rho_x',0.25);
            model = load_nk(options);
            solution = solve_re(model);
            gamma = find(strcmp(model.variable_names,'gamma_x'));
            testCase.verifyEqual(model.calibration.rho_x,0.25,'AbsTol',1e-12);
            testCase.verifyEqual(solution.transition(gamma,gamma),0.25, ...
                'AbsTol',1e-10);
        end
    end
end

function model = load_nk(options)
root = setup_project();
model = load_model(fullfile(root,'models','nk_balanced_growth.mod'),options);
end
