function idx = ir_variable_indices()
%% IR_VARIABLE_INDICES Named positions for model and impulse-response series.

idx.rk = 1;
idx.wage = 2;
idx.bond = 3;
idx.output = 4;
idx.hours = 5;
idx.caput = 6;
idx.capital = 7;
idx.mp = 8;
idx.investment = 9;
idx.rk_sum = 10;
idx.w_sum = 11;
idx.consumption = 12;
idx.gamma_x = 13;
idx.eps_x = 1;

idx.cons = idx.consumption;
idx.invst = idx.investment;
idx.cap = idx.capital;

idx.ir_series_count = 14;
idx.ir_wage = 1;
idx.ir_consumption = 2;
idx.ir_investment = 3;
idx.ir_output = 4;
idx.ir_bond = 5;
idx.ir_hours = 6;
idx.ir_rk = 7;
idx.ir_wage_level = 8;
idx.ir_rk_1q = 9;
idx.ir_wage_1q = 10;
idx.ir_rk_3q = 11;
idx.ir_rk_4q = 12;
idx.ir_wage_3q = 13;
idx.ir_wage_4q = 14;

end
