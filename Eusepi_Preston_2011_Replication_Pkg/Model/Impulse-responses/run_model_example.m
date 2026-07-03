% run_model_example.m
% Example parameterization for Model_Sept_2009.
% These are the parameters E&P initially had in model file, commented out.

setup_ir_paths();
config = ir_default_config();

param = config.model.param;

[A, C, invA0, k_y, disc, invalid_params] = Model_Sept_2009(param);
