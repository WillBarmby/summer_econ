function test_dynare_expectation_reference()
%% TEST_DYNARE_EXPECTATION_REFERENCE Compare direct evaluator with Dynare 7.1.

configure_dynare_71();
reset_dynare_71_globals();
model_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))),'models');
work = tempname; mkdir(work);
copyfile(fullfile(model_dir,'var_expectation_poc.mod'),work);
old = pwd; cleanup = onCleanup(@() cd(old)); cd(work);
dynare var_expectation_poc noclearall nolog;
global M_
plm = struct('intercept',zeros(2,1),'transition',[0.4 0.1;0.2 0.3]);
one = evaluate_var_expectation(plm,make_expectation_spec('one',[1 0],1,1));
infv = evaluate_var_expectation(plm,make_expectation_spec('inf',[1 0],[0 Inf],0.9));
p1 = M_.params(M_.var_expectation.one_step.param_indices);
pinf = M_.params(M_.var_expectation.infinite_sum.param_indices);
assert(max(abs(p1(:)-one.augmented_coefficients(:))) < 1e-14);
assert(max(abs(pinf(:)-infv.augmented_coefficients(:))) < 1e-14);
set_param_value('a11',0.55); set_param_value('a12',-0.05);
var_expectation.initialize('one_step'); var_expectation.update('one_step');
var_expectation.initialize('infinite_sum'); var_expectation.update('infinite_sum');
plm.transition=[0.55 -0.05;0.2 0.3];
one=evaluate_var_expectation(plm,make_expectation_spec('one',[1 0],1,1));
infv=evaluate_var_expectation(plm,make_expectation_spec('inf',[1 0],[0 Inf],0.9));
assert(max(abs(M_.params(M_.var_expectation.one_step.param_indices)-one.augmented_coefficients(:)))<1e-14);
assert(max(abs(M_.params(M_.var_expectation.infinite_sum.param_indices)-infv.augmented_coefficients(:)))<1e-14);
fprintf('Dynare 7.1 expectation reference tests passed.\n');
end
