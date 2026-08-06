function names = equation_names(M,n)
%% EQUATION_NAMES Prefer Dynare's human-readable equation tags.

names = arrayfun(@(j) sprintf('equation_%d',j),1:n, ...
    'UniformOutput',false);
if isfield(M,'equations_tags') && ~isempty(M.equations_tags)
    tags = M.equations_tags;
    for j = 1:size(tags,1)
        if strcmp(tags{j,2},'name')
            names{tags{j,1}} = tags{j,3};
        end
    end
end
end
