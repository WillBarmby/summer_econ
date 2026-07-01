function export_main_plot_pdfs
%% Run main_plot.m and export the generated figures as PDFs.

plot_dir = fileparts(mfilename('fullpath'));
imp_resp_dir = fullfile(plot_dir, '..');
export_dir = fullfile(imp_resp_dir, 'plot_exports', 'pdf');

if ~exist(export_dir, 'dir')
    mkdir(export_dir);
end

old_dir = pwd;
cleanup = onCleanup(@() cd(old_dir));

cd(plot_dir);
evalin('base', 'run(''main_plot.m'')');

fig_nums = [1 2 3 4];
fig_names = { ...
    'quantities', ...
    'expected_sums', ...
    'forecast_errors_and_rk_path', ...
    'rk_10_years_ahead_forecast' ...
};

for ii = 1:numel(fig_nums)
    fig = figure(fig_nums(ii));
    set(fig, 'PaperPositionMode', 'auto');
    print(fig, fullfile(export_dir, [fig_names{ii} '.pdf']), ...
        '-dpdf', '-painters', '-bestfit');
end

fprintf('Saved %d PDF figures to:\n%s\n', numel(fig_nums), export_dir);

end
