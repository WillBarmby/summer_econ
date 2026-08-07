function artifact = run_case(prepared,design)
%% RUN_CASE Convenience composition of TRAIN_CASE followed by RUN_IRF.

required = {'irf';'provenance';'summary';'training'};
if ~isstruct(design) || ~isscalar(design) || ...
        ~isequal(sort(fieldnames(design)),required)
    error('AdaptiveLearning:InvalidStudyDesign', ...
        'run_case requires a learning_irf_design value.');
end
training = train_case(prepared,design.training);
if training.status=="completed"
    irf = run_irf(prepared,training,design.irf);
    status = irf.status; termination = irf.termination;
else
    irf = [];
    status = training.status; termination = training.termination;
    termination.stage = "training";
end
artifact = build_training_irf_artifact(design,training,irf,status,termination);
end
