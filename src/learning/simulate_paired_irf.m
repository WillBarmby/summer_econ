function paired = simulate_paired_irf(learning_model,training_shocks, ...
    ir_shocks,impulse,initial_values,initial_beliefs,explosion_policy)
%% SIMULATE_PAIRED_IRF Train once, restart, and subtract baseline from shock.
% The baseline and shocked paths begin from exactly the same terminal state
% and belief estimates produced by training. They also receive identical IRF
% innovations except for the requested first-period impulse. Subtraction
% therefore isolates the impulse response while allowing beliefs to update
% endogenously and differently along the two post-training paths.

training = simulate_learning(learning_model,training_shocks,initial_values, ...
    initial_beliefs,explosion_policy);
if training.status~="completed"
    paired = incomplete_pair(training,[],[],"training_"+training.status);
    return
end
restart_values = training.native_path(:,end);
restart_beliefs = training.learning_state;
baseline = simulate_learning(learning_model,ir_shocks,restart_values, ...
    restart_beliefs,explosion_policy);
shocked_ir = ir_shocks;
shocked_ir(:,1) = shocked_ir(:,1)+impulse(:);
shocked = simulate_learning(learning_model,shocked_ir,restart_values, ...
    restart_beliefs,explosion_policy);
if baseline.status~="completed"
    paired = incomplete_pair(training,baseline,shocked, ...
        "baseline_"+baseline.status);
    return
end
if shocked.status~="completed"
    paired = incomplete_pair(training,baseline,shocked, ...
        "shocked_"+shocked.status);
    return
end
paired = struct('training',training,'baseline',baseline,'shocked',shocked, ...
    'native_irf',shocked.native_path(:,2:end)- ...
    baseline.native_path(:,2:end),'status',"completed");
end

function paired = incomplete_pair(training,baseline,shocked,status)
paired = struct('training',training,'baseline',baseline,'shocked',shocked, ...
    'native_irf',[],'status',status);
end
