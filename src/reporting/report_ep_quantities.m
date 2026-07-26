function reported = report_ep_quantities(native,variable_names)
%% REPORT_EP_QUANTITIES Convert stationary E&P paths to observable responses.
% The explicit E&P model expresses log-linear deviations in percentage-point
% units: a value of 1 denotes approximately one percent. Output, consumption,
% and investment are detrended, so adding cumulative technology growth restores
% their level responses. Hours is stationary and needs no trend restoration.

requested = {'output','consumption','investment','hours','gamma_x'};
[found,index] = ismember(requested,variable_names);
assert(all(found),'EPResearch:MissingVariable','Missing E&P report variable.');
technology_level = cumsum(native(index(5),:),2);
reported = [native(index(1),:)+technology_level; ...
    native(index(2),:)+technology_level; ...
    native(index(3),:)+technology_level;native(index(4),:)];
end
