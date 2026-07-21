function model = convert_first_order_to_log_deviations(model,log_variables)
%% CONVERT_FIRST_ORDER_TO_LOG_DEVIATIONS Rescale additive deviations.
%
% For each named positive variable, Delta x = x_bar * x_hat. Structural
% matrix columns, Dynare's decision rule, and stored first-order IRFs are all
% transformed into the same proportional/log-deviation coordinates.

validate_canonical_model(model);
assert(isfield(model,'normalization') && ...
    string(model.normalization.coordinate)=="additive_deviation", ...
    'FirstOrderNormalization:SourceCoordinate', ...
    'The source model must use additive deviations.');
assert((iscellstr(log_variables) || isstring(log_variables)) && ...
    isvector(log_variables), ...
    'FirstOrderNormalization:VariableList', ...
    'log_variables must be a cell or string vector of variable names.');
log_variables=cellstr(log_variables);
assert(numel(unique(log_variables))==numel(log_variables), ...
    'FirstOrderNormalization:VariableList', ...
    'log_variables must contain unique variable names.');

[found,indices]=ismember(log_variables,model.variable_names);
assert(all(found),'FirstOrderNormalization:UnknownVariable', ...
    'Unknown log-deviation variable: %s',strjoin(log_variables(~found),', '));
steady_state=model.re.steady_state(:);
assert(numel(steady_state)==numel(model.variable_names));
assert(all(steady_state(indices)>0), ...
    'FirstOrderNormalization:NonpositiveSteadyState', ...
    'Log-deviation variables must have positive steady states.');

scale=ones(numel(model.variable_names),1);
scale(indices)=steady_state(indices);
scaling=diag(scale);
model.current=model.current*scaling;
model.lag=model.lag*scaling;
model.lead=model.lead*scaling;

dr=model.re.decision_rule;
row_scale=scale(dr.order_var);
state_scale=scale(dr.state_var);
dr.ghx=(dr.ghx.*state_scale(:).')./row_scale(:);
dr.ghu=dr.ghu./row_scale(:);
model.re.decision_rule=dr;

irfs=model.re.irfs;
for i=indices(:).'
    for j=1:numel(model.shock_names)
        field=[model.variable_names{i} '_' model.shock_names{j}];
        if isfield(irfs,field)
            irfs.(field)=irfs.(field)/scale(i);
        end
    end
end
model.re.irfs=irfs;

if numel(indices)==numel(model.variable_names)
    coordinate="log_deviation";
else
    coordinate="mixed_log_and_additive_deviation";
end
model.normalization=struct('coordinate',coordinate,'scale',scale, ...
    'log_variables',{log_variables}, ...
    'interpretation','level deviation = scale .* canonical deviation');
validate_canonical_model(model);
end
