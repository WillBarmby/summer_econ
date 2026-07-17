function test_ep_archive_moments()
%% TEST_EP_ARCHIVE_MOMENTS Check timing and transformations by construction.

T=12;
path=zeros(13,T);
idx=ir_variable_indices();
path(idx.wage,:)=0:T-1;
path(idx.consumption,:)=2*(0:T-1);
path(idx.investment,:)=3*(0:T-1);
path(idx.output,:)=4*(0:T-1);
path(idx.gamma_x,:)=0.5;
path(idx.bond,:)=10+(0:T-1);
path(idx.hours,:)=(0:T-1).^2;

series=transform_ep_archive_series(path,1);
assert(isequal(size(series.levels),[6 T-1]));
assert(max(abs(series.quarterly_growth(:,1)-[1.5;2.5;3.5;4.5]))<1e-12);
assert(max(abs(series.annualized_growth(5,:)-4*path(idx.bond,2:end)))<1e-12);
assert(max(abs(series.annualized_growth(6,:)-4*diff(path(idx.hours,:))))<1e-12);

forecasts=NaN(size(path));
forecasts(idx.wage,2:end-1)=path(idx.wage,3:end)-(-1).^(1:T-2);
config=struct('sample_start',1,'hp_lambda',1600,'gamma_bar',1);
moments=calculate_ep_archive_moments(path,forecasts,config);
expected_error=(-1).^(1:T-2);
assert(max(abs(moments.wage_forecast_error-expected_error))<1e-12);
assert(abs(moments.table5_values(8)+1)<1e-12);
fprintf('E&P archive transformation and forecast timing test passed.\n');
end
