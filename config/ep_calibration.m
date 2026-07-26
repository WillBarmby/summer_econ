function calibration = ep_calibration(gamma_bar)
%% EP_CALIBRATION Declare the active E&P structural calibration override.
% Parameters not listed here remain exactly as declared in the two provenance-
% preserving Dynare model files. Keeping gamma_bar explicit makes the growth
% sensitivity a configuration change rather than an edit to model equations.

if nargin==0
    gamma_bar = exp(0.0053);
end
assert(isnumeric(gamma_bar) && isscalar(gamma_bar) && ...
    isfinite(gamma_bar) && gamma_bar>0,'EPResearch:InvalidCalibration', ...
    'gamma_bar must be a positive finite scalar.');
calibration = struct('gamma_bar',gamma_bar, ...
    'parameter_overrides',struct('gamma_bar',gamma_bar), ...
    'source','Eusepi and Preston (2011) replication calibration');
end
