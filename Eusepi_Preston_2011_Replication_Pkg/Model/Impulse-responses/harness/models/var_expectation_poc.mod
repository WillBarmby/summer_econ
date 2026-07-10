// Dynare 7.1 reference oracle for direct expectation evaluation.
var x y f_one f_sum;
varexo e_x e_y;
parameters a11 a12 a21 a22 beta;
a11=0.40; a12=0.10; a21=0.20; a22=0.30; beta=0.90;

var_model(model_name=plm, eqtags=['plm_x','plm_y']);
var_expectation_model(model_name=one_step, expression=x,
                      auxiliary_model_name=plm, horizon=1, discount=1);
// Dynare 7.1 accepts range syntax without square brackets.
var_expectation_model(model_name=infinite_sum, expression=x,
                      auxiliary_model_name=plm, horizon=0:Inf, discount=beta);

model(linear);
 [name='plm_x'] x=a11*x(-1)+a12*y(-1)+e_x;
 [name='plm_y'] y=a21*x(-1)+a22*y(-1)+e_y;
 f_one=var_expectation(one_step);
 f_sum=var_expectation(infinite_sum);
end;

var_expectation.initialize('one_step');
var_expectation.initialize('infinite_sum');
var_expectation.update('one_step');
var_expectation.update('infinite_sum');
