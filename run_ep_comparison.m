function results = run_ep_comparison(varargin)
%% RUN_EP_COMPARISON Run the public E&P RE/EE/IH comparison.
% With no arguments, the completed runner will use the documented defaults.
% With two arguments, it will require a complete configuration and output
% directory. The minimal engine is intentionally not installed in Phase 1.

setup_project();
results = struct(); %#ok<NASGU>
error('EPResearch:EngineNotInstalled', ...
    ['The clean E&P engine is not installed yet. This public runner becomes ' ...
     'active after the engine-extraction and E&P-interface phases.']);
end
