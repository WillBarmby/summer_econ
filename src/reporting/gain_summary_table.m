function output = gain_summary_table(summary)
%% GAIN_SUMMARY_TABLE Flatten a standard gain-grid summary to a table.

S = numel(summary.specification_ids);
G = numel(summary.gains);
Q = numel(summary.quantity_names);
rows = S*G*Q;
specification = strings(rows,1);
gain = NaN(rows,1);
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
    for g = 1:G
        for q = 1:Q
            row = row+1;
            specification(row) = string(summary.specification_ids{s});
            gain(row) = summary.gains(g);
            quantity(row) = string(summary.quantity_names{q});
            maximum_absolute_median_learning_minus_re_wedge(row) = ...
                summary.maximum_absolute_median_learning_minus_re_wedge(s,g,q);
            attempted_draws(row) = summary.attempted_draw_count(s,g);
            completed_draws(row) = summary.completed_draw_count(s,g);
            explosive_draws(row) = summary.explosive_draw_count(s,g);
            invalid_draws(row) = summary.invalid_draw_count(s,g);
            completion_rate(row) = summary.completion_rate(s,g);
            failure_rate(row) = summary.failure_rate(s,g);
        end
    end
end
output = table(specification,gain,quantity, ...
    maximum_absolute_median_learning_minus_re_wedge,attempted_draws, ...
    completed_draws,explosive_draws,invalid_draws,completion_rate, ...
    failure_rate,response_unit,first_horizon,last_horizon);
end
