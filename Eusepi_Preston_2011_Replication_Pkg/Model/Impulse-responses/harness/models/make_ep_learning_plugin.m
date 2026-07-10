function [plugin,state] = make_ep_learning_plugin(param,shock_variance)
%% MAKE_EP_LEARNING_PLUGIN Adapt E&P learning to the generic engine.

if nargin<1, cfg=ir_default_config(); param=cfg.main.model_param; end
if nargin<2, cfg=ir_default_config(); shock_variance=cfg.main.shock_scale^2; end
model=load_legacy_ep_model(param);
n=numel(model.variable_names); n_eq=7;
base0=model.re.plm_intercept;
baseC=model.re.plm_transition;
cap=find(strcmp(model.variable_names,'capital'));
B=[base0(1:n_eq),baseC(1:n_eq,cap)];
R=eye(2);
vcv=VCV_Model(model.re.transition,model.re.shock_impact,shock_variance);
R(2,2)=vcv(cap,cap);
learning=struct('initial_coefficients',B,'initial_moment_matrix',R, ...
    'gain',struct('type','constant','value',param(6),'offset',500), ...
    'rcond_tolerance',model_simul_default_options().r_matrix_tolerance, ...
    'project',@(candidate,old) project_capital(candidate,old,cap));
state=initialize_learning_state(learning);
plugin=struct();
plugin.name='E&P legacy-compatible learning';
plugin.model=model;
plugin.learning=learning;
plugin.beliefs_to_plm=@(s) beliefs_to_plm(s,base0,baseC,cap,n_eq);
plugin.plm_to_alm=@(plm) legacy_alm(model,plm);
plugin.regressor=@(y,t) [1;y(cap,t-1)];
plugin.outcome=@(y,t) y(1:n_eq,t);
plugin.re_plm=struct('intercept',base0,'transition',baseC);
plugin.explosion_limit=1000;
end

function plm=beliefs_to_plm(state,base0,baseC,cap,n_eq)
plm=struct('intercept',base0,'transition',baseC);
plm.intercept(1:n_eq)=state.coefficients(:,1);
plm.transition(1:n_eq,cap)=state.coefficients(:,2);
end

function alm=legacy_alm(model,plm)
[a,b,c]=ALM_fun(model.expectation_matrices,model.transformed_shock, ...
    model.inv_current,plm.intercept,plm.transition, ...
    model.forecast_horizon,model.discounts);
alm=struct('intercept',a,'transition',b,'shock_impact',c);
end

function [candidate,projected]=project_capital(candidate,old,cap)
projected=false;
if cap<=size(candidate,1) && abs(candidate(cap,2))>0.99
    candidate(cap,2)=old(cap,2); projected=true;
end
end
