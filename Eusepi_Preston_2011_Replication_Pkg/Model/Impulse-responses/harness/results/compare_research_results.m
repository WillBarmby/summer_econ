function comparison=compare_research_results(left,right)
%% COMPARE_RESEARCH_RESULTS Align cross-model output by standardized names.

shared=intersect(fieldnames(left.observables),fieldnames(right.observables),'stable');
comparison=struct('left_model',left.model,'right_model',right.model, ...
    'shared_observables',{shared},'observables',struct(), ...
    'invalid_run_share',[left.diagnostics.invalid_run_share,right.diagnostics.invalid_run_share]);
for j=1:numel(shared)
    comparison.observables.(shared{j})=struct( ...
        'left',{left.observables.(shared{j})},'right',{right.observables.(shared{j})});
end
end
