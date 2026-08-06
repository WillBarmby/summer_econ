function components = extract_nonlinear_components(context,options)
%% EXTRACT_NONLINEAR_COMPONENTS Linearize levels and transform deviation units.

M = context.M;
oo = context.oo;
n = M.endo_nbr;
steady = oo.steady_state(:);
if ~isequal(size(steady),[n 1]) || ~all(isfinite(steady))
    error('AdaptiveLearning:InvalidSteadyState', ...
        'Dynare did not return a finite deterministic steady state.');
end
level = extract_analytical_jacobian(context,steady);
names = cellstr(string(M.endo_names(:).'));
scales = resolve_deviation_scales(steady,names,options.deviation_scales);
S = diag(scales);
components = struct( ...
    'current',level.current*S,'lag',level.lag*S,'lead',level.lead*S, ...
    'shock',level.shock,'variable_names',{names}, ...
    'shock_names',{cellstr(string(M.exo_names(:).'))}, ...
    'equation_names',{equation_names(M,n)}, ...
    'calibration',parameter_struct(M), ...
    'transformation',struct('kind',"scaled_deviation", ...
        'level_steady_state',steady,'deviation_scales',scales, ...
        'scale_overrides',options.deviation_scales));
end

function scales = resolve_deviation_scales(steady,names,overrides)
scales = steady/100;
override_names = fieldnames(overrides);
for j = 1:numel(override_names)
    [found,index] = ismember(override_names{j},names);
    if ~found
        error('AdaptiveLearning:UnknownVariable', ...
            'Deviation scale names unknown variable "%s".',override_names{j});
    end
    scales(index) = overrides.(override_names{j});
end
missing = ~isfinite(scales) | scales<=0;
if any(missing)
    error('AdaptiveLearning:MissingDeviationScale', ...
        'Supply positive deviation scales for: %s.',strjoin(names(missing),', '));
end
end
