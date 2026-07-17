function report = test_ep_ee_code_discrepancy(n_draws)
%% TEST_EP_EE_CODE_DISCREPANCY Compare RE, archived EE, and stated-paper EE.
% All three specifications receive identical innovations. The archive EE
% keeps consumption beliefs at RE; paper EE recursively learns consumption
% as required by the text following equation (17).

if nargin==0, n_draws=20; end
assert(isscalar(n_draws) && n_draws>=1 && n_draws==fix(n_draws));
model_path=fullfile(fileparts(mfilename('fullpath')),'harness','models', ...
    'ep_ee_paper.mod');
model=load_dynare_71_linear_model(model_path);
simulation=ep_ee_paper_config();
simulation.n_draws=n_draws;
gains=[0.002 0.04];
names={'sigma_y','sigma_c_over_y','sigma_i_over_y','sigma_h_over_y', ...
    'rho_dc','rho_dy','rho_di','rho_wage_fe'};
rows={};

for gain=gains
    paper_config=ep_ee_learning_config("paper",gain);
    archive_config=ep_ee_learning_config("archive",gain);
    [paper_plugin,paper_initial]=make_dynare_ee_learning_plugin( ...
        model,paper_config,simulation.shock_scale^2);
    [archive_plugin,archive_initial]=make_dynare_ee_learning_plugin( ...
        model,archive_config,simulation.shock_scale^2);
    assert(any(strcmp(paper_plugin.learned_outcomes,'consumption')));
    assert(~any(strcmp(archive_plugin.learned_outcomes,'consumption')));

    policy=ir_default_config().main.explosion_policy;
    policy.variable_indices=1:numel(model.variable_names);
    values=NaN(8,n_draws,3);
    distance=NaN(n_draws,2);
    completed=zeros(1,3); explosive=zeros(1,3); invalid=zeros(1,3);
    rng(simulation.seed,'twister');
    for draw=1:n_draws
        shocks=simulation.shock_scale*randn(1,simulation.path_length-1);
        [re_path,re_forecasts]=simulate_re(model,paper_plugin.re_plm,shocks);
        archive=simulate_learning_path(archive_plugin,shocks,zeros(10,1), ...
            archive_initial,policy);
        paper=simulate_learning_path(paper_plugin,shocks,zeros(10,1), ...
            paper_initial,policy);
        runs={struct('native_path',re_path,'one_step_forecasts',re_forecasts), ...
            archive,paper};
        statuses=["completed",archive.status,paper.status];
        for specification=1:3
            completed(specification)=completed(specification) ...
                +(statuses(specification)=="completed");
            explosive(specification)=explosive(specification) ...
                +(statuses(specification)=="explosive");
            invalid(specification)=invalid(specification) ...
                +(statuses(specification)=="invalid");
            if statuses(specification)=="completed"
                [path13,forecast13]=map_to_archive_rows(runs{specification}, ...
                    model.variable_names);
                result=calculate_ep_archive_moments(path13,forecast13,simulation);
                values(:,draw,specification)=result.table5_values;
            end
        end
        retained=simulation.sample_start+1:simulation.path_length;
        if archive.status=="completed"
            distance(draw,1)=rms_difference(archive.native_path(:,retained), ...
                re_path(:,retained));
        end
        if paper.status=="completed"
            distance(draw,2)=rms_difference(paper.native_path(:,retained), ...
                re_path(:,retained));
        end
    end

    labels=["RE";"archive_EE";"paper_EE"];
    means=squeeze(mean(values,2,'omitnan'))';
    distances=[0;mean(distance,1,'omitnan')'];
    for j=1:3
        rows(end+1,:)={gain,labels(j),means(j,:),distances(j), ...
            completed(j),explosive(j),invalid(j)}; %#ok<AGROW>
    end
end

report=table(cell2mat(rows(:,1)),string(rows(:,2)),vertcat(rows{:,3}), ...
    cell2mat(rows(:,4)),cell2mat(rows(:,5)),cell2mat(rows(:,6)), ...
    cell2mat(rows(:,7)),'VariableNames',{'gain','specification','moments', ...
    'rms_path_distance_from_re','completed','explosive','invalid'});
report.Properties.UserData.moment_names=names;
fprintf('\nMatched EE specification comparison (%d draws)\n',n_draws);
for j=1:height(report)
    fprintf(['gain=%-6g %-10s distance from RE = %.6g ' ...
        '[completed=%d explosive=%d invalid=%d]\n'],report.gain(j), ...
        report.specification(j),report.rms_path_distance_from_re(j), ...
        report.completed(j),report.explosive(j),report.invalid(j));
    disp(array2table(report.moments(j,:),'VariableNames',names));
end

% This is a specification test, not a test that presumes the economic answer.
% It requires only that the two implementations are genuinely distinct.
small=report.gain==0.002;
archive_row=find(small & report.specification=="archive_EE");
paper_row=find(small & report.specification=="paper_EE");
assert(norm(report.moments(archive_row,:)-report.moments(paper_row,:))>1e-8, ...
    'Paper and archive EE unexpectedly produced identical reported moments.');
fprintf('EE code-discrepancy comparison completed successfully.\n');
end

function [path,forecasts]=simulate_re(model,plm,shocks)
alm=plm_to_alm_linear(model,plm);
T=size(shocks,2)+1;
path=zeros(numel(model.variable_names),T);
forecasts=NaN(size(path));
for t=2:T
    path(:,t)=alm.intercept+alm.transition*path(:,t-1) ...
        +alm.shock_impact*shocks(:,t-1);
    forecasts(:,t)=plm.intercept+plm.transition*path(:,t);
end
end

function [path13,forecast13]=map_to_archive_rows(run,names)
idx=ir_variable_indices();
path13=zeros(13,size(run.native_path,2));
forecast13=NaN(13,size(run.one_step_forecasts,2));
shared={'rk','wage','output','hours','caput','capital','investment', ...
    'consumption','gamma_x'};
for j=1:numel(shared)
    source=find(strcmp(names,shared{j}),1);
    destination=idx.(shared{j});
    path13(destination,:)=run.native_path(source,:);
    forecast13(destination,:)=run.one_step_forecasts(source,:);
end
end

function value=rms_difference(x,y)
difference=x-y;
value=sqrt(mean(difference(:).^2));
end
