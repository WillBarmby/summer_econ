function result = run_learning_specification(learning_model,id,label, ...
    standardized_innovations,config,impulse,report_function,shock_name)
%% RUN_LEARNING_SPECIFICATION Train and simulate one named learning model.
% shock_name selects the single innovation used for training and the impulse.
% Every other shock is held exactly at zero. This makes shock isolation explicit
% in models, such as NK, that declare more than one structural disturbance.

n = numel(learning_model.model.variable_names);
q = numel(learning_model.model.shock_names);
[found,shock_index] = ismember(shock_name,learning_model.model.shock_names);
assert(found, ...
    'EPResearch:ShockContract', ...
    'The model does not declare requested shock %s.',shock_name);
impulse_vector = zeros(q,1);
impulse_vector(shock_index) = impulse;
re_native = make_re_irf(learning_model,config.ir_periods,impulse_vector);
re_reported = report_function(re_native,learning_model.model.variable_names);
quantity_count = size(re_reported,1);
raw = NaN(config.draw_count,quantity_count,config.ir_periods);
statuses = strings(config.draw_count,1);
terminations = cell(config.draw_count,1);
coefficient_shape = size(learning_model.initial_beliefs.coefficients);
moment_shape = size(learning_model.initial_beliefs.moment_matrix);
terminal_coefficients = NaN([config.draw_count coefficient_shape]);
terminal_moments = NaN([config.draw_count moment_shape]);
training_projection_events = NaN(config.draw_count,1);
policy = struct('magnitude_limit',config.explosion_magnitude, ...
    'reject_nonfinite',true,'variable_indices',1:n);

for draw = 1:config.draw_count
    % Only the selected disturbance receives the recorded scalar innovations.
    shocks = zeros(q,config.training_periods+config.ir_periods);
    shocks(shock_index,:) = standardized_innovations(draw,:)* ...
        config.training_shock_standard_deviation;
    training = shocks(:,1:config.training_periods);
    ir_shocks = shocks(:,config.training_periods+1:end);
    paired = simulate_paired_irf(learning_model,training,ir_shocks, ...
        impulse_vector,zeros(n,1),learning_model.initial_beliefs,policy);
    % Save the beliefs used to start both IRF paths. These diagnostics make it
    % possible to distinguish "learning stayed near RE" from "updates never
    % occurred" without rerunning a Monte Carlo draw.
    trained_beliefs = paired.training.learning_state;
    terminal_coefficients(draw,:,:) = trained_beliefs.coefficients;
    terminal_moments(draw,:,:) = trained_beliefs.moment_matrix;
    training_projection_events(draw) = trained_beliefs.projection_events;
    statuses(draw) = paired.status;
    if paired.status=="completed"
        raw(draw,:,:) = report_function(paired.native_irf, ...
            learning_model.model.variable_names);
        terminations{draw} = struct();
    else
        terminations{draw} = find_termination(paired);
    end
end

completed = statuses=="completed";
summary = summarize_learning_draws(raw,re_reported,config.band_probabilities);
result = struct('id',id,'label',label,'model_name',learning_model.model.name, ...
    'backend',learning_model.model.backend, ...
    'effective_calibration',learning_model.model.calibration, ...
    'variable_names',{learning_model.model.variable_names}, ...
    'learning_specification',learning_model.specification, ...
    're_native_path',re_native,'re_reported_path',re_reported, ...
    'learning_draws',raw,'summary',summary,'statuses',statuses, ...
    'initial_beliefs',learning_model.initial_beliefs, ...
    'terminal_training_coefficients',terminal_coefficients, ...
    'terminal_training_moments',terminal_moments, ...
    'training_projection_events',training_projection_events, ...
    'terminations',{terminations},'status_counts',struct( ...
    'completed',sum(completed),'explosive',sum(contains(statuses,"explosive")), ...
    'invalid',sum(contains(statuses,"invalid"))));
result.units = struct('reported_responses', ...
    "percent deviation under the parent artifact's reporting transformation");
result.periods = struct('frequency',"quarterly", ...
    'matlab_indices',1:config.ir_periods, ...
    'horizons',0:config.ir_periods-1,'impact_matlab_index',1, ...
    'impact_horizon',0);
result.axes = standard_simulation_axes();
end

function termination = find_termination(paired)
% Preserve the first failed stage so unsuccessful draws remain auditable.
for name = {'training','baseline','shocked'}
    run = paired.(name{1});
    if ~isempty(run) && run.status~="completed"
        termination = run.termination;
        termination.stage = name{1};
        return
    end
end
termination = struct();
end
