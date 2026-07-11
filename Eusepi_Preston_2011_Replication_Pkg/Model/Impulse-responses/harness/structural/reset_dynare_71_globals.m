function reset_dynare_71_globals()
%% RESET_DYNARE_71_GLOBALS Remove stale base-workspace state before Dynare.
%
% Dynare drivers execute in the base workspace and expect M_ and oo_ to be
% global structs. With noclearall, a pre-existing numeric oo_ can otherwise
% survive and make var_expectation.initialize fail on dot assignment.

evalin('base','clear global M_ oo_; clear M_ oo_;');
clear global M_ oo_
end
