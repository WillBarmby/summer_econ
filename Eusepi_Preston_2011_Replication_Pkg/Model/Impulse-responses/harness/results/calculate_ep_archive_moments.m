function result = calculate_ep_archive_moments(native_path,one_step_forecasts,config)
%% CALCULATE_EP_ARCHIVE_MOMENTS Compute the published EE comparison moments.
% The first seven outputs correspond to Table 5: HP-filtered output
% volatility; relative consumption, investment, and hours volatility; the
% first autocorrelation of consumption, output, and investment growth. The
% final diagnostic is the archive's one-quarter wage forecast-error
% autocorrelation.

required={'sample_start','hp_lambda','gamma_bar'};
assert(isstruct(config) && all(isfield(config,required)), ...
    'EPMoments:InvalidConfig','Moment configuration is incomplete.');
series=transform_ep_archive_series(native_path,config.gamma_bar);
assert(config.sample_start>=1 && config.sample_start<=size(series.levels,2)-2, ...
    'EPMoments:InvalidSample','sample_start leaves too few observations.');

levels=series.levels(:,config.sample_start:end);
growth=series.annualized_growth(:,config.sample_start:end);
cycle=hp_cycle(levels,config.hp_lambda);
level_sd=std(cycle,0,2);

result=struct();
result.table5_names={'sigma_y','sigma_c_over_y','sigma_i_over_y', ...
    'sigma_h_over_y','rho_dc','rho_dy','rho_di','rho_wage_fe'};
result.table5_values=[level_sd(4);level_sd(2)/level_sd(4); ...
    level_sd(3)/level_sd(4);level_sd(6)/level_sd(4); ...
    lag_one(growth(2,:));lag_one(growth(4,:));lag_one(growth(3,:));NaN];

if ~isempty(one_step_forecasts)
    assert(isequal(size(one_step_forecasts),size(native_path)), ...
        'EPMoments:InvalidForecasts','Forecasts must match native_path size.');
    idx=ir_variable_indices();
    % Forecast made in t (archive column t) is evaluated against t+1.
    wage_error=native_path(idx.wage,3:end)-one_step_forecasts(idx.wage,2:end-1);
    wage_error=wage_error(config.sample_start:end);
    result.table5_values(8)=lag_one(wage_error);
    result.wage_forecast_error=wage_error;
else
    result.wage_forecast_error=[];
end
result.transformed=series;
result.sample_cycle=cycle;
result.sample_growth=growth;
end

function cycle=hp_cycle(data,lambda)
assert(isscalar(lambda) && isfinite(lambda) && lambda>0, ...
    'EPMoments:InvalidLambda','hp_lambda must be positive and finite.');
T=size(data,2);
D=diff(speye(T),2);
trend=(speye(T)+lambda*(D'*D))\data';
cycle=data-trend';
end

function value=lag_one(x)
value=corr(x(2:end)',x(1:end-1)');
end
