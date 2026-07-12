function paired = simulate_paired_irf(plugin, training_shocks, ir_shocks, impulse, initial_y, initial_learning, explosion_policy)
%% SIMULATE_PAIRED_IRF Train once, restart, and compare shocked/baseline paths.

training = simulate_learning_path(plugin,training_shocks,initial_y,initial_learning,explosion_policy);
if training.status ~= "completed"
    paired = incomplete_pair(training,[],[],"training_"+training.status);
    return
end
restart_y = training.native_path(:,end);
restart_learning = training.learning_state;
baseline = simulate_learning_path(plugin,ir_shocks,restart_y,restart_learning,explosion_policy);
shocked_ir = ir_shocks;
shocked_ir(:,1) = shocked_ir(:,1)+impulse(:);
shocked = simulate_learning_path(plugin,shocked_ir,restart_y,restart_learning,explosion_policy);
if baseline.status ~= "completed"
    paired = incomplete_pair(training,baseline,shocked,"baseline_"+baseline.status);
    return
end
if shocked.status ~= "completed"
    paired = incomplete_pair(training,baseline,shocked,"shocked_"+shocked.status);
    return
end
paired = struct('training',training,'baseline',baseline,'shocked',shocked, ...
    'native_irf',shocked.native_path(:,2:end)-baseline.native_path(:,2:end), ...
    'status',"completed");
end

function paired = incomplete_pair(training,baseline,shocked,status)
paired = struct('training',training,'baseline',baseline,'shocked',shocked, ...
    'native_irf',[],'status',status);
end
