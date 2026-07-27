function summary = summarize_learning_draws(raw,re_path,probabilities)
%% SUMMARIZE_LEARNING_DRAWS Compute pointwise bands without replacing failures.
% raw is draw-by-quantity-by-period. Failed draws remain NaN in the artifact
% and are excluded here; their statuses are reported separately.

assert(ndims(raw)==3 && size(re_path,1)==size(raw,2) && ...
    size(re_path,2)==size(raw,3),'EPResearch:SummaryDimensions', ...
    'Learning draws and RE path have incompatible dimensions.');
usable = raw(~all(isnan(raw),[2 3]),:,:);
if isempty(usable)
    % A parameter-map cell with no admissible draws is a result, not a missing
    % experiment. Preserve its RE benchmark and return NaN learning summaries;
    % the companion status counts identify why all histories failed.
    missing = NaN(size(re_path));
    summary = struct('learning_median',missing,'learning_low',missing, ...
        'learning_high',missing,'re',re_path, ...
        'band_probabilities',probabilities,'completed_draw_count',0);
    return
end
ordered = sort(usable,1);
n = size(ordered,1);
summary = struct('learning_median',squeeze(median(usable,1)), ...
    'learning_low',squeeze(ordered(max(1,ceil(probabilities(1)*n)),:,:)), ...
    'learning_high',squeeze(ordered(min(n,ceil(probabilities(2)*n)),:,:)), ...
    're',re_path,'band_probabilities',probabilities, ...
    'completed_draw_count',n);
end
