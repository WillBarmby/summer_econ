function report = reconstruct_ep_table5_archive(archive_root,output_dir)
%% RECONSTRUCT_EP_TABLE5_ARCHIVE Rebuild EE Table 5 from saved 5,000 draws.

assert(nargin==2 && isfolder(archive_root),'EPEE:MissingArchive', ...
    'archive_root must be the historical Simulation-Codes directory.');
if ~isfolder(output_dir), mkdir(output_dir); end
folders={'simulation_codes_Euler_sg_162','simulation_codes_Euler_162'};
gains=[0.002 0.04];
published=[1.31 .54 2.43 .49 .08 -.01 -.03 .00; ...
           1.31 .54 2.43 .49 .08  .00 -.02 .09];
names={'sigma_y','sigma_c_over_y','sigma_i_over_y','sigma_h_over_y', ...
    'rho_dc','rho_dy','rho_di','rho_wage_fe'};
rows=cell(0,7);
draws=cell(1,2);
for j=1:2
    source=fullfile(archive_root,folders{j},'results_RBC_162.mat');
    assert(isfile(source),'EPEE:MissingArchive','Missing %s.',source);
    saved=load(source);
    draws{j}=[saved.var_moments_level_mat(1:4,:); ...
        saved.Auto_corr_growth_mat(1,:);saved.Auto_corr_growth_mat(5,:); ...
        saved.Auto_corr_growth_mat(2,:);saved.acorr_w1_mat];
    assert(size(draws{j},2)==5000,'EPEE:ArchiveDrawCount', ...
        'Expected exactly 5,000 archived draws.');
    reconstructed=mean(draws{j},2);
    stored=[saved.mean_L(1:4);saved.mean_autog(1);saved.mean_autog(5); ...
        saved.mean_autog(2);saved.mean_aw1];
    assert(max(abs(reconstructed-stored))<1e-12, ...
        'EPEE:ArchiveMeanMismatch','Stored means do not reconstruct exactly.');
    standard_error=std(draws{j},0,2)/sqrt(5000);
    for k=1:numel(names)
        rows(end+1,:)={gains(j),string(names{k}),reconstructed(k), ...
            standard_error(k),published(j,k),reconstructed(k)-published(j,k), ...
            round(reconstructed(k),2)==published(j,k)}; %#ok<AGROW>
    end
end
report=cell2table(rows,'VariableNames',{'gain','moment','archive_mean', ...
    'monte_carlo_se','published','difference','rounded_match'});
writetable(report,fullfile(output_dir,'ep_ee_archived_table5.csv'));
write_markdown(report,fullfile(output_dir,'ep_ee_archived_table5.md'));
save(fullfile(output_dir,'ep_ee_archived_table5.mat'),'report','draws');
end

function write_markdown(report,path)
fid=fopen(path,'w');
assert(fid>=0,'EPEE:WriteFailure','Could not create %s.',path);
cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'# Archived E&P EE Table 5 Reconstruction\n\n');
fprintf(fid,'| Gain | Moment | Archive mean | MC SE | Published | Difference | Rounded match |\n');
fprintf(fid,'|---:|---|---:|---:|---:|---:|:---:|\n');
for j=1:height(report)
    fprintf(fid,'| %.3g | %s | %.9f | %.9f | %.2f | %+.9f | %s |\n', ...
        report.gain(j),report.moment(j),report.archive_mean(j), ...
        report.monte_carlo_se(j),report.published(j),report.difference(j), ...
        string(report.rounded_match(j)));
end
ratio=1.31/report.archive_mean(report.gain==.002 & report.moment=="sigma_y");
fprintf(fid,['\nThe seven relative-volatility/autocorrelation entries round to the ' ...
    'published values. Absolute output volatility does not: reproducing 1.31 ' ...
    'would require multiplying the small-gain archived value by %.9f. ' ...
    'No transformation is applied here; the discrepancy remains unresolved.\n'],ratio);
end
