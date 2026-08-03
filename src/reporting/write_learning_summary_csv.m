function write_learning_summary_csv(summary,path)
%% WRITE_LEARNING_SUMMARY_CSV Flatten a standard learning summary.

S = numel(summary.specification_ids);
Q = numel(summary.quantity_names);
rows = S*Q;
specification = strings(rows,1);
quantity = strings(rows,1);
maximum_absolute_median_learning_minus_re_wedge = NaN(rows,1);
attempted_draws = NaN(rows,1);
completed_draws = NaN(rows,1);
explosive_draws = NaN(rows,1);
invalid_draws = NaN(rows,1);
completion_rate = NaN(rows,1);
failure_rate = NaN(rows,1);
response_unit = repmat(string(summary.response_unit),rows,1);
first_horizon = repmat(summary.reported_horizons(1),rows,1);
last_horizon = repmat(summary.reported_horizons(end),rows,1);
row = 0;
for s = 1:S
    for q = 1:Q
        row = row+1;
        specification(row) = string(summary.specification_ids{s});
        quantity(row) = string(summary.quantity_names{q});
        maximum_absolute_median_learning_minus_re_wedge(row) = ...
            summary.maximum_absolute_median_learning_minus_re_wedge(s,q);
        attempted_draws(row) = summary.attempted_draw_count(s);
        completed_draws(row) = summary.completed_draw_count(s);
        explosive_draws(row) = summary.explosive_draw_count(s);
        invalid_draws(row) = summary.invalid_draw_count(s);
        completion_rate(row) = summary.completion_rate(s);
        failure_rate(row) = summary.failure_rate(s);
    end
end
writetable(table(specification,quantity, ...
    maximum_absolute_median_learning_minus_re_wedge,attempted_draws, ...
    completed_draws,explosive_draws,invalid_draws,completion_rate, ...
    failure_rate,response_unit,first_horizon,last_horizon),path);
end
