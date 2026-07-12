function comparison = compare_ir_implementations(config, tolerance)
%% COMPARE_IR_IMPLEMENTATIONS Run legacy and explicit paths from identical RNG state.

validate_ir_config(config);
if ~isnumeric(tolerance) || ~isscalar(tolerance) || ~isfinite(tolerance) || tolerance < 0
    error('IRComparison:InvalidTolerance','tolerance must be a finite nonnegative scalar.');
end

initial_rng = rng;
cleanup = onCleanup(@() rng(initial_rng));
legacy = run_legacy_irf(config);
rng(initial_rng);
[new_raw,new_median,new_low,new_up,new_draws] = run_impulse_responses(config);

comparison = struct('equivalent',true,'tolerance',tolerance, ...
    'maximum_absolute_difference',0,'legacy',legacy, ...
    'new',struct('imp_resp_vec',{new_raw},'median_imp_resp_vec',{new_median}, ...
    'low_band',{new_low},'up_band',{new_up},'draw_results',{new_draws}));
groups = {{legacy.imp_resp_vec,new_raw},{legacy.median_imp_resp_vec,new_median}, ...
    {legacy.low_band,new_low},{legacy.up_band,new_up}};
for group_index = 1:numel(groups)
    left = groups{group_index}{1}; right = groups{group_index}{2};
    if numel(left) ~= numel(right)
        comparison.equivalent = false;
        return
    end
    for series_index = 1:numel(left)
        if ~isequal(size(left{series_index}),size(right{series_index}))
            comparison.equivalent = false;
            return
        end
        difference = max(abs(left{series_index}(:)-right{series_index}(:)),[],'omitnan');
        if isempty(difference), difference = 0; end
        comparison.maximum_absolute_difference = max( ...
            comparison.maximum_absolute_difference,difference);
    end
end
comparison.equivalent = comparison.maximum_absolute_difference <= tolerance;
if ~comparison.equivalent
    error('IRComparison:NumericalMismatch', ...
        'Legacy and explicit IR results differ by %.16g (tolerance %.16g).', ...
        comparison.maximum_absolute_difference,tolerance);
end
end
