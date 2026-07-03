function ir_series = build_ir_series(Y_var, expectations, idx, current_cols, lag_cols)
%% BUILD_IR_SERIES Construct the 14 reported impulse-response series.
%
% LIST of VARS: {'w','c','i','y','b','h','rk','we','Exprk1','Expw1',
% 'Exprk20','Exprk40','Expwe20','Expwe40'}

growth_rows = [idx.wage; idx.cons; idx.invst; idx.output];

y_growth_vec = Y_var(growth_rows,current_cols)-Y_var(growth_rows,lag_cols)+...
    ones(numel(growth_rows),1)*Y_var(idx.gamma_x,current_cols);

y_detr_vec = zeros(size(y_growth_vec,1),size(y_growth_vec,2));
y_detr_vec(:,1) = y_growth_vec(:,1);

%% NOTE: the initial observation corresponds to the initial growth rate.
for j = 2:size(y_growth_vec,2)
    y_detr_vec(:,j) = y_growth_vec(:,j)+y_detr_vec(:,j-1);
end

ir_series = [y_detr_vec;Y_var(idx.bond,current_cols);Y_var(idx.hours,current_cols);...
    Y_var(idx.rk,current_cols);Y_var(idx.wage,current_cols);...
    expectations.Exp_rk_1Q(current_cols);expectations.Exp_w_1Q(current_cols);...
    expectations.Exp_rk_3Q(current_cols);expectations.Exp_rk_4Q(current_cols);...
    expectations.Exp_w_3Q(current_cols);expectations.Exp_w_4Q(current_cols);];

end
