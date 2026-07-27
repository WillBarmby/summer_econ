function reported = report_common_quantities(native,variable_names)
%% REPORT_COMMON_QUANTITIES Put E&P and NK paths in comparable level units.
% Both stationary models express output, consumption, and investment relative
% to the stochastic technology trend. Their reported level response therefore
% equals the stationary percentage deviation plus cumulative technology
% growth. Hours is already stationary and needs no trend restoration.

requested = {'output','consumption','investment','hours','gamma_x'};
[found,index] = ismember(requested,variable_names);
assert(all(found),'EPResearch:MissingVariable', ...
    'A comparison model is missing a common reported variable.');
technology_level = cumsum(native(index(5),:),2);
reported = [native(index(1),:)+technology_level; ...
    native(index(2),:)+technology_level; ...
    native(index(3),:)+technology_level;native(index(4),:)];
end
