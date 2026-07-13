function report = verify_ep10_structural_re()
%% VERIFY_EP10_STRUCTURAL_RE Independent 10-variable structural RE benchmark.

if nargin~=0
    error('Verification:UnexpectedInput', ...
        'The verification model path is fixed inside the test boundary.');
end
model_path=fullfile(fileparts(mfilename('fullpath')),'models', ...
    'ep10_euler_re_verification.mod');
dyn=load_dynare_71_linear_model(model_path);
cfg=ir_default_config(); param=cfg.main.model_param; param(1)=0;
legacy=load_legacy_ep_model(param);
names={'rk','wage','output','hours','consumption','investment','capital','gamma_x'};
H=40; differences=zeros(numel(names),1);
for j=1:numel(names)
    d=dyn.re.irfs.([names{j} '_eps_x'])(1:H); d=d(:);
    row=find(strcmp(legacy.variable_names,names{j}));
    r=zeros(H,1); r(1)=legacy.re.shock_impact(row);
    state=legacy.re.shock_impact;
    for t=2:H
        state=legacy.re.transition*state; r(t)=state(row);
    end
    differences(j)=max(abs(d-r));
end
assert(max(differences)<1e-12, ...
    '10-variable structural RE mismatch: %.16g.',max(differences));
report=table(string(names(:)),differences,'VariableNames',{'variable','max_abs_diff'});
fprintf('10-variable structural RE verification passed; max diff %.3g.\n',max(differences));
end
