function series = transform_ep_archive_series(native_path,gamma_bar)
%% TRANSFORM_EP_ARCHIVE_SERIES Reproduce the E&P Table 5 data transform.
% Native variables are stationary model coordinates. Growing variables are
% converted to quarterly growth and reconstructed levels; bond and hours
% remain stationary. Rows are ordered wage, consumption, investment,
% output, bond, and hours, as in the archived bus_cycle_stats_fun.m.

if nargin~=2 || ~isnumeric(native_path) || size(native_path,1)~=13 || ...
        size(native_path,2)<2 || ~isscalar(gamma_bar) || gamma_bar<=0
    error('EPMoments:InvalidTransformInput', ...
        'Supply a 13-by-T native path (T>=2) and a positive gamma_bar.');
end

idx=ir_variable_indices();
growing=[idx.wage idx.consumption idx.investment idx.output];
quarterly_growth=native_path(growing,2:end)-native_path(growing,1:end-1) ...
    +native_path(idx.gamma_x,2:end);

% Initial constants only shift an entire reconstructed series and therefore
% do not affect its HP cycle. Zero is clearer than retaining opaque archive
% steady-state constants; the archive's deterministic growth trend is exact.
levels=cumsum(quarterly_growth+100*log(gamma_bar),2);
series=struct();
series.names={'wage','consumption','investment','output','bond','hours'};
series.levels=[levels;native_path(idx.bond,2:end);native_path(idx.hours,2:end)];
series.annualized_growth=4*[quarterly_growth;native_path(idx.bond,2:end); ...
    diff(native_path(idx.hours,:),1,2)];
series.quarterly_growth=quarterly_growth;
series.native_periods=2:size(native_path,2);
end
