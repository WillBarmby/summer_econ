function reported = report_nk_nominal_quantities(native,variable_names)
%% REPORT_NK_NOMINAL_QUANTITIES Report real and nominal stationary responses.
% Technology is held fixed in the risk-premium experiment, so the stationary
% output, consumption, investment, and hours deviations are also their level
% responses. Inflation and the nominal rate are proportional percentage
% deviations from their gross steady-state values under the loader's unit rule.

requested = {'output','consumption','investment','hours', ...
    'inflation','nominal_rate'};
[found,index] = ismember(requested,variable_names);
assert(all(found),'EPResearch:MissingVariable', ...
    'The NK model is missing a requested risk-premium report variable.');
reported = native(index,:);
end
