function reported = report_nk_technology_nominal_quantities(native,variable_names)
%% REPORT_NK_TECHNOLOGY_NOMINAL_QUANTITIES Report NK real and nominal responses.
% Output, consumption, and investment are stationary NK variables measured
% relative to the stochastic technology trend. Restore the cumulative
% technology response before reporting them, as in report_common_quantities.
% Inflation and the nominal rate are already proportional percentage
% deviations from their gross steady-state values.

requested = {'output','consumption','investment','hours', ...
    'inflation','nominal_rate','gamma_x'};
[found,index] = ismember(requested,variable_names);
assert(all(found),'EPResearch:MissingVariable', ...
    'The NK model is missing a requested technology-shock report variable.');
technology_level = cumsum(native(index(7),:),2);
reported = [native(index(1),:)+technology_level; ...
    native(index(2),:)+technology_level; ...
    native(index(3),:)+technology_level; ...
    native(index(4),:);native(index(5),:);native(index(6),:)];
end
