function paired = simulate_paired_irf(plugin, training_shocks, ir_shocks, impulse, initial_y, initial_learning)
%% SIMULATE_PAIRED_IRF Train once, restart, and compare shocked/baseline paths.

training = simulate_learning_path(plugin,training_shocks,initial_y,initial_learning);
assert(~training.invalid,'Training simulation is invalid.');
restart_y = training.native_path(:,end);
restart_learning = training.learning_state;
baseline = simulate_learning_path(plugin,ir_shocks,restart_y,restart_learning);
shocked_ir = ir_shocks;
shocked_ir(:,1) = shocked_ir(:,1)+impulse(:);
shocked = simulate_learning_path(plugin,shocked_ir,restart_y,restart_learning);
paired = struct('training',training,'baseline',baseline,'shocked',shocked, ...
    'native_irf',shocked.native_path(:,2:end)-baseline.native_path(:,2:end));
end
