function results = build_research_results(model, formulation, runs, observable_map, metadata)
%% BUILD_RESEARCH_RESULTS Standardized cross-model research output.

if ~iscell(runs), runs = {runs}; end
results = struct();
results.model = model.name;
results.expectations_formulation = formulation.name;
results.variable_names = model.variable_names;
results.native = runs;
results.observables = struct();
keys = fieldnames(observable_map);
for k = 1:numel(keys)
    native_name = observable_map.(keys{k});
    idx = find(strcmp(model.variable_names,native_name),1);
    if ~isempty(idx)
        results.observables.(keys{k}) = cellfun(@(r) r.native_path(idx,:),runs,'UniformOutput',false);
    end
end
results.diagnostics = struct();
results.diagnostics.invalid_run_share = mean(cellfun(@(r) r.invalid,runs));
results.diagnostics.invalid_flags = cellfun(@(r) r.invalid,runs);
results.diagnostics.expectation_errors = cellfun(@collect_errors,runs,'UniformOutput',false);
results.diagnostics.belief_distance_from_re = cellfun(@(r) r.belief_distance_from_re,runs,'UniformOutput',false);
results.diagnostics.plm_stability_roots = cellfun(@(r) r.plm_stability_root,runs,'UniformOutput',false);
results.diagnostics.alm_stability_roots = cellfun(@(r) r.alm_stability_root,runs,'UniformOutput',false);
results.diagnostics.projection_events = cellfun(@(r) r.learning_state.projection_events,runs);
results.diagnostics.observations_processed = cellfun(@(r) r.learning_state.observations,runs);
results.diagnostics.terminal_belief_distance = cellfun(@terminal_distance,runs);
results.metadata = metadata;
end

function values=collect_errors(run)
valid=run.diagnostics(~cellfun('isempty',run.diagnostics));
if isempty(valid), values=[]; return; end
values=cell2mat(cellfun(@(d) d.prediction_error(:),valid,'UniformOutput',false));
end

function value=terminal_distance(run)
x=run.belief_distance_from_re;
x=x(isfinite(x));
if isempty(x), value=NaN; else, value=x(end); end
end
