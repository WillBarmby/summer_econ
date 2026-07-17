function test_ep_ee_paper_specification()
%% TEST_EP_EE_PAPER_SPECIFICATION Enforce equation (17)'s consumption PLM.

model_path=fullfile(fileparts(fileparts(mfilename('fullpath'))),'models', ...
    'ep_ee_paper.mod');
model=load_dynare_71_linear_model(model_path);
config=ep_ee_learning_config("paper",0.002);
assert(isequal(config.learned_outcomes,{'rk','consumption','capital'}));
[plugin,state]=make_dynare_ee_learning_plugin(model,config,exp(-0.144)^2);
assert(isequal(plugin.learned_outcomes,{'rk','consumption','capital'}));

% A subjective change to expected consumption must change the EE actual law
% of motion. This fails if consumption is accidentally left fixed at RE.
baseline=plugin.beliefs_to_plm(state);
changed=baseline;
consumption=find(strcmp(model.variable_names,'consumption'),1);
capital=find(strcmp(model.variable_names,'capital'),1);
changed.transition(consumption,capital)= ...
    changed.transition(consumption,capital)+0.05;
alm0=plugin.plm_to_alm(baseline);
alm1=plugin.plm_to_alm(changed);
assert(norm(alm1.transition-alm0.transition,'fro')>1e-6);
fprintf('Paper-faithful EE consumption-forecast specification passed.\n');
end
