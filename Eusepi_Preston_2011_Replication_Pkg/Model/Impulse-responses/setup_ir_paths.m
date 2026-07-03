function model_dir = setup_ir_paths()
%% SETUP_IR_PATHS Add shared impulse-response dependencies to the path.

model_dir = fileparts(mfilename('fullpath'));
pkg_dir = fileparts(fileparts(model_dir));

addpath(fullfile(model_dir, 'config'), '-end');
addpath(fullfile(model_dir, 'model'), '-end');
addpath(fullfile(model_dir, 'generation'), '-end');
addpath(fullfile(model_dir, 'io'), '-end');
addpath(fullfile(pkg_dir, 'Common'), '-end');

end
