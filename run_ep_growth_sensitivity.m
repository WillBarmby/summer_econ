function growth = run_ep_growth_sensitivity(varargin)
%% RUN_EP_GROWTH_SENSITIVITY Compare original and zero deterministic growth.
% The completed runner will execute only E&P EE and IH specifications under
% identical technology-growth innovations and random draws. It will never
% load the temporary NK model.

setup_project();
growth = struct(); %#ok<NASGU>
error('EPResearch:EngineNotInstalled', ...
    ['The clean E&P engine is not installed yet. This public runner becomes ' ...
     'active after the engine-extraction and E&P-interface phases.']);
end
