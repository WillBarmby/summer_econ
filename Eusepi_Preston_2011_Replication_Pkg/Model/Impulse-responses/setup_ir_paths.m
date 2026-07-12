function model_dir = setup_ir_paths()
%% SETUP_IR_PATHS Add shared impulse-response dependencies to the path.

model_dir = fileparts(mfilename('fullpath'));
pkg_dir = fileparts(fileparts(model_dir));

addpath(fullfile(model_dir, 'config'), '-end');
addpath(fullfile(model_dir, 'model'), '-end');
addpath(fullfile(model_dir, 'generation'), '-end');
addpath(fullfile(model_dir, 'io'), '-end');
addpath(fullfile(model_dir, 'legacy_irf'), '-end');
addpath(fullfile(model_dir, 'harness'), '-end');
addpath(fullfile(model_dir, 'harness', 'structural'), '-end');
addpath(fullfile(model_dir, 'harness', 'expectations'), '-end');
addpath(fullfile(model_dir, 'harness', 'learning'), '-end');
addpath(fullfile(model_dir, 'harness', 'results'), '-end');
addpath(fullfile(model_dir, 'harness', 'models'), '-end');
addpath(fullfile(model_dir, 'harness', 'tests'), '-end');
addpath(fullfile(pkg_dir, 'Common'), '-end');

end
