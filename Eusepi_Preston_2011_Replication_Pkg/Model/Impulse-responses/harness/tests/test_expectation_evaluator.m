function test_expectation_evaluator()
%% TEST_EXPECTATION_EVALUATOR Direct formulas and E&P IH normalization.

rng(7);
n = 5;
C = randn(n)*0.08;
mu = randn(n,1)*0.01;
plm = struct('intercept',mu,'transition',C);
alpha = zeros(1,n); alpha(2)=1;
one = evaluate_var_expectation(plm,make_expectation_spec('one',alpha,1,1));
assert(max(abs(one.coefficients-alpha*C)) < 1e-14);
assert(abs(one.intercept-alpha*mu) < 1e-14);
beta = 0.96;
pv = evaluate_var_expectation(plm,make_expectation_spec('pv',alpha/beta,[1 Inf],beta));
legacy_F1 = alpha*C/(eye(n)-beta*C);
legacy_F0 = alpha*((eye(n)-C)\((eye(n)/(1-beta)-C/(eye(n)-beta*C))*mu));
assert(max(abs(pv.coefficients-legacy_F1)) < 1e-12);
assert(abs(pv.intercept-legacy_F0) < 1e-12);
bad = plm; bad.transition = eye(n)/beta;
failed = false;
try
    evaluate_var_expectation(bad,make_expectation_spec('bad',alpha,[0 Inf],beta));
catch
    failed = true;
end
assert(failed,'Unstable infinite sum must be rejected.');
fprintf('Direct expectation evaluator tests passed.\n');
end
