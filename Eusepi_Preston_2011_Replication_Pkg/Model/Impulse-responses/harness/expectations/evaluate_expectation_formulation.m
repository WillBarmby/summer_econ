function values = evaluate_expectation_formulation(plm, formulation)
%% EVALUATE_EXPECTATION_FORMULATION Evaluate every declared forecast block.

values = repmat(struct(),numel(formulation.blocks),1);
for j = 1:numel(formulation.blocks)
    values(j) = evaluate_var_expectation(plm, formulation.blocks(j));
end
end
