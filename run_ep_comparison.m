function results = run_ep_comparison(varargin)
%% RUN_EP_COMPARISON Run the public E&P RE/EE/IH comparison.
% Research question: holding the E&P RBC structure and shock history fixed,
% how do RE, paper-direct one-step EE, and verified IH responses differ?
% With no arguments, use the documented 100-draw defaults and save beneath
% results/ep_comparison. Otherwise supply both a complete config and output
% directory. EE and IH always receive the same standardized random draws.

root = setup_project();
if nargin==0
    config = ep_experiment_config();
    output_dir = fullfile(root,'results','ep_comparison');
elseif nargin==2
    config = varargin{1};
    output_dir = varargin{2};
else
    error('EPResearch:RequiredArguments', ...
        'Supply both a complete config and output directory, or neither.');
end
results = run_ep_experiment(config,output_dir,'ep_comparison');
end
