function config = nk_model_calibration_config(variant)
%% NK_MODEL_CALIBRATION_CONFIG Source and comparison NK calibrations.

if nargin~=1
    error('NKCalibration:RequiredVariant','Supply source or iid_comparison.');
end
config=struct();
config.variant=string(variant);
config.source_reference='NK_Models/model/model_simple.tex, Model 2';
config.source_parameters=struct( ...
    'beta',0.995,'eta',1/3,'delta',0.025,'alpha',0.33, ...
    'theta',6,'varphi',59.11,'inflation_bar',1.006, ...
    'phi_pi',1.5,'phi_y',0.1,'rho_technology',0.9, ...
    'technology_bar',1,'hours_bar',1/3);
config.source_shock_standard_deviation=0.0025;
switch config.variant
    case "source"
        config.parameter_overrides=struct();
    case "iid_comparison"
        config.parameter_overrides=struct('rho_technology',0);
    otherwise
        error('NKCalibration:InvalidVariant', ...
            'variant must be source or iid_comparison.');
end
end
