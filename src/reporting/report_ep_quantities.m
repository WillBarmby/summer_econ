function reported = report_ep_quantities(native,variable_names)
%% REPORT_EP_QUANTITIES Convert stationary E&P paths to observable responses.
% The explicit E&P model expresses log-linear deviations in percentage-point
% units: a value of 1 denotes approximately one percent. Output, consumption,
% and investment are detrended, so adding cumulative technology growth restores
% their level responses. Hours is stationary and needs no trend restoration.

reported = report_common_quantities(native,variable_names);
end
