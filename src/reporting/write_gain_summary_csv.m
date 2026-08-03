function write_gain_summary_csv(summary,path)
%% WRITE_GAIN_SUMMARY_CSV Flatten a standard gain-grid summary.

writetable(gain_summary_table(summary),path);
end
