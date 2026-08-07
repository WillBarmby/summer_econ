function options = ep_case_options()
%% EP_CASE_OPTIONS Model and learning assumptions for E&P cases.
shock_scale = exp(-0.034);
options = struct('gain',0.002,'gamma_bar',exp(0.0053), ...
    'belief_shock_covariance',shock_scale^2, ...
    'rcond_tolerance',1e-12,'ih_rcond_tolerance',1.0856345e-10);
end
