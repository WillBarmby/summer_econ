function specification = nk_risk_premium_ee_specification(gain)
%% NK_RISK_PREMIUM_EE_SPECIFICATION EE assumptions for the i.i.d. demand shock.
% The learned endogenous forecasts are identical to the technology experiment.
% The realized risk-premium innovation is observed but excluded from the PLM.
% That exclusion is coherent here only because rho_s=0: the innovation contains
% no information about next period's premium. A persistent-premium experiment
% must add the observed premium to the forecasting state instead.

specification = nk_ee_specification(gain);
specification.variant = "nk_risk_premium_one_step";
specification.observed_but_excluded = {'eps_s'};
end
