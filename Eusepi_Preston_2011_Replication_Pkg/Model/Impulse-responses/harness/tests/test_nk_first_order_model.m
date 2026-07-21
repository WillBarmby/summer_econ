function test_nk_first_order_model()
%% TEST_NK_FIRST_ORDER_MODEL Verify raw and normalized NK first-order systems.

model_path=fullfile(fileparts(fileparts(mfilename('fullpath'))),'models', ...
    'nk_nonlinear_rotemberg_pricing.mod');
source_config=nk_model_calibration_config("source");
raw=load_dynare_71_first_order_model(model_path);
assert(strlength(raw.dynare.work_directory)==0);
assert(string(raw.normalization.coordinate)=="additive_deviation");
assert_source_calibration(raw,source_config);

% Only derivatives that survive at first order count as expectations.
lead_names=raw.variable_names(any(abs(raw.lead)>1e-12,1));
assert(isequal(lead_names,{'rk','consumption','inflation'}));

% The technology equation fixes the shock-column sign convention.
technology=find(strcmp(raw.variable_names,'technology'),1);
technology_eq=find(strcmp(raw.equation_names,'technology'),1);
rho=raw.calibration.rho_technology;
assert(abs(raw.current(technology_eq,technology)-1)<1e-12);
assert(abs(raw.lag(technology_eq,technology)+rho)<1e-12);
assert(abs(raw.shock(technology_eq,1)+1)<1e-12);

[raw_transition,raw_shock]=dynare_re_law(raw);
assert_re_fixed_point(raw,raw_transition,raw_shock,1e-10);
assert_dynare_irfs(raw,raw_transition,raw_shock,1e-10);

normalized=convert_first_order_to_log_deviations(raw,raw.variable_names);
assert(string(normalized.normalization.coordinate)=="log_deviation");
[log_transition,log_shock]=dynare_re_law(normalized);
scale=raw.re.steady_state(:);
expected_transition=diag(1./scale)*raw_transition*diag(scale);
expected_shock=diag(1./scale)*raw_shock;
assert(max(abs(log_transition-expected_transition),[],'all')<1e-12);
assert(max(abs(log_shock-expected_shock),[],'all')<1e-12);
assert_re_fixed_point(normalized,log_transition,log_shock,1e-10);
assert_dynare_irfs(normalized,log_transition,log_shock,1e-10);

% The named comparison changes the solved model without changing its source.
iid_config=nk_model_calibration_config("iid_comparison");
iid=load_dynare_71_first_order_model(model_path, ...
    'ParameterOverrides',iid_config.parameter_overrides);
assert(iid.calibration.rho_technology==0);
assert(isequal(iid.dynare.parameter_overrides,iid_config.parameter_overrides));
iid_technology=find(strcmp(iid.variable_names,'technology'),1);
iid_equation=find(strcmp(iid.equation_names,'technology'),1);
assert(abs(iid.lag(iid_equation,iid_technology))<1e-12);
[iid_transition,iid_shock]=dynare_re_law(iid);
assert_re_fixed_point(iid,iid_transition,iid_shock,1e-10);
assert(norm(iid_transition-raw_transition,'fro')>1e-3, ...
    'NKFirstOrder:OverrideDidNotResolve', ...
    'The persistence override did not change the solved decision rule.');
fprintf('NK raw/log first-order RE and Dynare IRF equivalence tests passed.\n');
end

function assert_source_calibration(model,config)
names=fieldnames(config.source_parameters);
for j=1:numel(names)
    name=names{j};
    assert(isfield(model.calibration,name));
    assert(abs(model.calibration.(name)-config.source_parameters.(name))<1e-12, ...
        'NKFirstOrder:SourceCalibrationDrift', ...
        'Source parameter %s differs from its documented value.',name);
end
actual=sqrt(model.re.shock_covariance(1,1));
assert(abs(actual-config.source_shock_standard_deviation)<1e-12, ...
    'NKFirstOrder:SourceCalibrationDrift', ...
    'Source technology shock standard deviation differs from its documented value.');
end

function [transition,shock]=dynare_re_law(model)
dr=model.re.decision_rule;
n=numel(model.variable_names);
transition=zeros(n);
transition(dr.order_var,dr.state_var)=dr.ghx;
shock=zeros(n,size(dr.ghu,2));
shock(dr.order_var,:)=dr.ghu;
end

function assert_re_fixed_point(model,transition,shock,tolerance)
lhs=model.current+model.lead*transition;
lag_error=max(abs(lhs*transition+model.lag),[],'all');
shock_error=max(abs(lhs*shock+model.shock),[],'all');
assert(lag_error<tolerance,'NKFirstOrder:RETransition', ...
    'Dynare RE transition misses the structural fixed point by %.3g.',lag_error);
assert(shock_error<tolerance,'NKFirstOrder:REShock', ...
    'Dynare RE shock impact misses the structural fixed point by %.3g.',shock_error);
plm=struct('intercept',zeros(numel(model.variable_names),1), ...
    'transition',transition);
alm=plm_to_alm_linear(model,plm);
assert(max(abs(alm.transition-transition),[],'all')<tolerance);
assert(max(abs(alm.shock_impact-shock),[],'all')<tolerance);
end

function assert_dynare_irfs(model,transition,shock,tolerance)
H=40;
standard_deviation=sqrt(model.re.shock_covariance(1,1));
path=zeros(numel(model.variable_names),H);
path(:,1)=shock(:,1)*standard_deviation;
for t=2:H
    path(:,t)=transition*path(:,t-1);
end
maximum=0;
compared=0;
for i=1:numel(model.variable_names)
    field=[model.variable_names{i} '_' model.shock_names{1}];
    if isfield(model.re.irfs,field)
        expected=model.re.irfs.(field)(1:H);
        maximum=max(maximum,max(abs(path(i,:)-expected(:).')));
        compared=compared+1;
    end
end
assert(compared>0,'NKFirstOrder:MissingIRFs','Dynare returned no comparable IRFs.');
assert(maximum<tolerance,'NKFirstOrder:IRFMismatch', ...
    'Reconstructed and Dynare IRFs differ by %.3g.',maximum);
end
