function save_ir_output(main_config, imp_resp_vec)
%% SAVE_IR_OUTPUT Save impulse responses using configured output metadata.

imp_resp_output.(main_config.output_var) = imp_resp_vec;

save(fullfile(main_config.output_dir, main_config.output_file), '-struct', 'imp_resp_output');

end
