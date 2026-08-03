function files = save_initialization_robustness(artifact,output_dir)
%% SAVE_INITIALIZATION_ROBUSTNESS Write the common artifact's paper outputs.

stem = fullfile(output_dir,'initialization_robustness');
files = struct('mat',[stem '.mat'],'summary_csv',[stem '_summary.csv']);
files = merge_structs(files,make_initialization_robustness_figures( ...
    artifact,output_dir));
write_summary(artifact,files.summary_csv);
end

function write_summary(artifact,path)
S = numel(artifact.specification_ids);
J = numel(artifact.training_horizons);
Q = numel(artifact.quantity_names);
rows = S*J*Q;
specification = strings(rows,1);
training_periods = NaN(rows,1);
quantity = strings(rows,1);
initialization_effect = NaN(rows,1);
learning_effect = NaN(rows,1);
relative_effect = NaN(rows,1);
completion_re = NaN(rows,1);
completion_half_re = NaN(rows,1);
joint_completion = NaN(rows,1);
median_displacement_retained = NaN(rows,1);
projection_rate_re = NaN(rows,1);
projection_rate_half_re = NaN(rows,1);
response_unit = repmat(string(artifact.summary.response_unit),rows,1);
first_horizon = repmat(artifact.summary.reported_horizons(1),rows,1);
last_horizon = repmat(artifact.summary.reported_horizons(end),rows,1);
row = 0;
for s = 1:S
    for j = 1:J
        for q = 1:Q
            row = row+1;
            specification(row) = artifact.specification_ids(s);
            training_periods(row) = artifact.training_horizons(j);
            quantity(row) = artifact.quantity_names{q};
            initialization_effect(row) = ...
                artifact.summary.median_max_initialization_effect(s,j,q);
            learning_effect(row) = artifact.summary.median_max_learning_effect(s,j,q);
            relative_effect(row) = artifact.summary.relative_initialization_effect(s,j,q);
            completion_re(row) = artifact.summary.rates(s,1,j,1);
            completion_half_re(row) = artifact.summary.rates(s,2,j,1);
            joint_completion(row) = artifact.summary.joint_completion_rate(s,j);
            median_displacement_retained(row) = median( ...
                artifact.summary.retained_initial_displacement(:,s,j),'omitnan');
            projection_rate_re(row) = artifact.summary.projection_event_rate(s,1,j);
            projection_rate_half_re(row) = ...
                artifact.summary.projection_event_rate(s,2,j);
        end
    end
end
writetable(table(specification,training_periods,quantity, ...
    initialization_effect,learning_effect,relative_effect,completion_re, ...
    completion_half_re,joint_completion,median_displacement_retained, ...
    projection_rate_re,projection_rate_half_re,response_unit,first_horizon, ...
    last_horizon),path);
end

function combined = merge_structs(first,second)
combined = first;
names = fieldnames(second);
for j = 1:numel(names), combined.(names{j}) = second.(names{j}); end
end
