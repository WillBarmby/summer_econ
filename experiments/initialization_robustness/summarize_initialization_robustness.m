function metrics = summarize_initialization_robustness(artifact)
%% SUMMARIZE_INITIALIZATION_ROBUSTNESS Apply one draw-first metric everywhere.
% The primary statistic takes each paired draw's largest absolute treatment
% difference over time, then takes the median across draws.

results = artifact.results;
S = size(results,1);
D = artifact.config.draw_count;
Q = numel(artifact.quantity_names);
H = artifact.config.ir_periods;
rates = NaN(S,2,3);
joint = false(D,S);
projections = NaN(D,S,2);
observations = NaN(D,S,2);
belief_from_re = NaN(D,S,2);
belief_pair = NaN(D,S);
retained = NaN(D,S);
learning_minus_re = NaN(D,S,2,Q,H);
initialization_difference = NaN(D,S,Q,H);

for specification = 1:S
    re_initial = results{specification,1}.initial_beliefs.coefficients;
    initial_displacement = norm(0.5*re_initial,'fro');
    trained = false(D,2);
    for treatment = 1:2
        result = results{specification,treatment};
        rates(specification,treatment,:) = [result.status_counts.completed, ...
            result.status_counts.explosive,result.status_counts.invalid]/D;
        projections(:,specification,treatment) = result.training_projection_events;
        observations(:,specification,treatment) = observations_reached( ...
            result,artifact.config.training_periods);
        trained(:,treatment) = training_completed(result);
        difference = result.terminal_training_coefficients- ...
            reshape(re_initial,[1 size(re_initial)]);
        distance = squeeze(sqrt(sum(difference.^2,[2 3])));
        distance(~trained(:,treatment)) = NaN;
        belief_from_re(:,specification,treatment) = distance;
        learning_minus_re(:,specification,treatment,:,:) = ...
            result.learning_draws-reshape(result.re_reported_path,[1 Q H]);
    end
    joint(:,specification) = results{specification,1}.statuses=="completed" & ...
        results{specification,2}.statuses=="completed";
    coefficient_difference = results{specification,2}.terminal_training_coefficients- ...
        results{specification,1}.terminal_training_coefficients;
    belief_pair(:,specification) = squeeze(sqrt(sum( ...
        coefficient_difference.^2,[2 3])));
    belief_pair(~all(trained,2),specification) = NaN;
    retained(:,specification) = belief_pair(:,specification)/initial_displacement;
    initialization_difference(:,specification,:,:) = ...
        learning_minus_re(:,specification,2,:,:)- ...
        learning_minus_re(:,specification,1,:,:);
end

draw_max_initialization = squeeze(max(abs(initialization_difference),[],4));
draw_max_learning = squeeze(max(abs(learning_minus_re(:,:,1,:,:)),[],5));
median_max_initialization = squeeze(median(draw_max_initialization,1,'omitnan'));
median_max_learning = squeeze(median(draw_max_learning,1,'omitnan'));
metrics = struct('rate_names',{{'completion','explosive','invalid'}}, ...
    'rates',rates,'joint_completion',joint, ...
    'joint_completion_rate',mean(joint,1), ...
    'projection_events',projections, ...
    'projection_event_rate',squeeze(mean(projections>0,1,'omitnan')), ...
    'observations_reached',observations, ...
    'belief_distance_from_re',belief_from_re, ...
    'paired_belief_distance',belief_pair, ...
    'retained_initial_displacement',retained, ...
    'learning_minus_re_irf',learning_minus_re, ...
    'initialization_difference_irf',initialization_difference, ...
    'draw_max_initialization_effect',draw_max_initialization, ...
    'median_max_initialization_effect',median_max_initialization, ...
    'draw_max_learning_effect',draw_max_learning, ...
    'median_max_learning_effect',median_max_learning, ...
    'relative_initialization_effect', ...
    median_max_initialization./median_max_learning);
end

function observations = observations_reached(result,requested)
observations = repmat(requested,numel(result.statuses),1);
for draw = 1:numel(result.statuses)
    termination = result.terminations{draw};
    if isfield(termination,'stage') && strcmp(termination.stage,'training')
        observations(draw) = max(0,termination.period-2);
    end
end
end

function completed = training_completed(result)
completed = true(numel(result.statuses),1);
for draw = 1:numel(result.statuses)
    termination = result.terminations{draw};
    completed(draw) = ~isfield(termination,'stage') || ...
        ~strcmp(termination.stage,'training');
end
end
