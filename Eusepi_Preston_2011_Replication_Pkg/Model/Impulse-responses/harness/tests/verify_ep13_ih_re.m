function report=verify_ep13_ih_re()
%% VERIFY_EP13_IH_RE Validate IH RE and align it with the Euler benchmark.

model_dir=fullfile(fileparts(fileparts(mfilename('fullpath'))),'models');
root=fileparts(fileparts(fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))))));
ih=load_dynare_71_linear_model(fullfile(model_dir,'ep13_ih_re_linear.mod'));
ee=load_dynare_71_linear_model(fullfile(root,'EP_RE_REDS_SOLDS_compare_sanitized.mod'));
cfg=ir_default_config(); legacy=load_legacy_ep_model(cfg.main.model_param);
names={'rk','wage','output','hours','consumption','investment','capital','gamma_x'};
H=40; ih_ee=zeros(numel(names),1); ih_legacy=zeros(numel(names),1);
for j=1:numel(names)
    a=ih.re.irfs.([names{j} '_eps_x'])(1:H); a=a(:);
    b=ee.re.irfs.([names{j} '_eps_x'])(1:H); b=b(:);
    ih_ee(j)=max(abs(a-b));
    row=find(strcmp(legacy.variable_names,names{j}));
    state=legacy.re.shock_impact; c=zeros(H,1); c(1)=state(row);
    for t=2:H, state=legacy.re.transition*state; c(t)=state(row); end
    ih_legacy(j)=max(abs(a-c));
end
assert(max(ih_ee)<1e-10,'IH and Euler RE shared dynamics differ by %.3g.',max(ih_ee));
assert(max(ih_legacy)<1e-10,'IH Dynare and legacy RE differ by %.3g.',max(ih_legacy));
report=table(string(names(:)),ih_ee,ih_legacy, ...
    'VariableNames',{'variable','ih_vs_euler','ih_vs_legacy'});
fprintf('13-variable IH RE verification passed; max shared diff %.3g.\n',max([ih_ee;ih_legacy]));
end
