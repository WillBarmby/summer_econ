function reset_dynare_state()
%% RESET_DYNARE_STATE Clear Dynare's global base-workspace outputs.
% Dynare drivers run in the base workspace. Clearing both global declarations
% and ordinary bindings prevents one model load from contaminating the next.

evalin('base','clear global M_ oo_; clear M_ oo_;');
clear global M_ oo_
end
