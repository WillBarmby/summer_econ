function test_ep_ee_belief_variants()
%% TEST_EP_EE_BELIEF_VARIANTS Distinguish archive, paper, and wage proxy.

model=load_ep_ee_dynare_model(1);
gain=0.04;
variance=exp(-0.144)^2;
variants=["archive","paper","wage_proxy"];
cfg=ir_default_config();
policy=cfg.main.explosion_policy;
policy.variable_indices=1:numel(model.variable_names);
recording=struct('record_beliefs',true);
rng(44,'twister');
shocks=exp(-0.144)*randn(1,199);
wage=find(strcmp(model.variable_names,'wage'),1);
consumption=find(strcmp(model.variable_names,'consumption'),1);

runs=cell(size(variants));
plugins=cell(size(variants));
for j=1:numel(variants)
    learning=ep_ee_learning_config(variants(j),gain);
    [plugins{j},initial]=make_dynare_ee_learning_plugin(model,learning,variance);
    runs{j}=simulate_learning_path(plugins{j},shocks,zeros(10,1),initial, ...
        policy,recording);
    assert(runs{j}.status=="completed");
end

archive=runs{1}.belief_history;
archive_re=plugins{1}.re_plm;
valid=2:size(archive.intercept,2);
assert(max(abs(archive.intercept(consumption,valid) ...
    -archive_re.intercept(consumption)))<1e-14);
assert(max(abs(archive.capital_slope(consumption,valid) ...
    -archive_re.transition(consumption,find(strcmp(model.variable_names,'capital')))))<1e-14);
assert(max(abs(diff(archive.capital_slope(wage,valid))))>1e-8);

paper=runs{2}.belief_history;
assert(max(abs(diff(paper.capital_slope(consumption,valid))))>1e-8);

proxy=runs{3}.belief_history;
assert(max(abs(proxy.intercept(consumption,valid)-proxy.intercept(wage,valid)))<1e-14);
assert(max(abs(proxy.capital_slope(consumption,valid) ...
    -proxy.capital_slope(wage,valid)))<1e-14);

baseline=plugins{2}.beliefs_to_plm(runs{2}.learning_state);
changed=baseline;
capital=find(strcmp(model.variable_names,'capital'),1);
changed.transition(consumption,capital)=changed.transition(consumption,capital)+0.05;
alm0=plugins{2}.plm_to_alm(baseline);
alm1=plugins{2}.plm_to_alm(changed);
assert(norm(alm1.transition-alm0.transition,'fro')>1e-6);
fprintf('Archive, paper, and wage-proxy EE belief diagnostics passed.\n');
end
