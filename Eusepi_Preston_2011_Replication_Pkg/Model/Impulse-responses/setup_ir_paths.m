function model_dir = setup_ir_paths()
%% SETUP_IR_PATHS Add shared impulse-response dependencies to the path.

model_dir = fileparts(mfilename('fullpath'));
pkg_dir = fileparts(fileparts(model_dir));

addpath(fullfile(pkg_dir, 'Common'), '-end');

end
