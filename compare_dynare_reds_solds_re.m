%% Minimal Dynare vs REDS/SOLDS RE runner.
clear; clc;

root = fileparts(mfilename('fullpath'));
if isempty(root), root = pwd; end

addpath('/Applications/Dynare/7.1-arm64/matlab');
addpath(fullfile(root, 'Eusepi_Preston_2011_Replication_Pkg', 'Common'));
addpath(fullfile(root, 'Eusepi_Preston_2011_Replication_Pkg', 'Model', 'Impulse-responses', 'config'));
addpath(fullfile(root, 'Eusepi_Preston_2011_Replication_Pkg', 'Model', 'Impulse-responses', 'model'));

% Actual impulse-response default used by the replication IR code:
%   x(1) = 1       infinite-horizon consumption rule in the learning code
%   x(2) = 0       no production externality
%   x(3) = 1       log consumption utility, sigma = 1
%   x(4) = 1       simple RBC case, so utilization is fixed/off
%   x(5) = 0.0001  inverse Frisch/labor-supply elasticity, near-linear labor
%   x(6) = 0.002   learning gain; valid but irrelevant in the RE comparison
cfg = ir_default_config();
x_ir_default = cfg.main.model_param(:).';

% This Dynare file is the one-period Euler-equation RE benchmark, not the
% paper/code's infinite-horizon learning consumption rule. Therefore we keep
% the IR calibration but change only x(1) from 1 to 0.
x = x_ir_default; x(1) = 0;
H = 40;  % number of impulse-response periods to pull from each solution

%% Dynare
outdir = fullfile(root, 'comparison_outputs', 'minimal_dynare_run');
if ~isfolder(outdir), mkdir(outdir); end
mod_src = fullfile(root, 'Eusepi_Preston_2011_Replication_Pkg', 'Model', ...
    'Impulse-responses', 'harness', 'tests', 'models', ...
    'ep10_euler_re_verification.mod');
[~, mod_name, mod_ext] = fileparts(mod_src);
copyfile(mod_src, fullfile(outdir, [mod_name, mod_ext]));

old = pwd; cleanup = onCleanup(@() cd(old));
cd(outdir);
dynare(mod_name, 'noclearall');
cd(old);

% Guard against accidentally comparing different labor-supply calibrations.
% The .mod file hard-codes eps_H, while REDS/SOLDS gets it from x(5).
param_names = string(M_.param_names);
dynare_eps_H = M_.params(param_names == "eps_H");
assert(abs(dynare_eps_H - x(5)) < 1e-14, 'Dynare eps_H and x(5) differ.');

% Dynare IRFs are named variable_shock. With var eps_x = 1 in the .mod,
% these are responses to a one-unit innovation in gamma_x/log technology
% growth, in the model's log-deviation units.
v = {'rk','wage','output','hours','consumption','investment','capital','gamma_x'};
for j = 1:numel(v)
    dynare_irfs.(v{j}) = oo_.irfs.([v{j} '_eps_x'])(1:H).';
end

%% REDS/SOLDS RE
% Build the same linear model matrices using the same x, then:
%   REDS_SOLDS_Model_Sept_2009 gives the initial RE coefficient guess,
%   REE_solve iterates the T-map to the RE fixed point,
%   ALM_fun returns the actual law of motion y_t = T_0 + T_L*y_{t-1} + T_s*eps_t.
[A, C, invA0, k_y, disc, invalid_params] = build_model_matrices(x);
assert(~invalid_params);
[OMEGA_0_RE, OMEGA_c_RE, invalid_params_reds] = REDS_SOLDS_Model_Sept_2009(x);
assert(~invalid_params_reds);
[OMEGA_0_RE, OMEGA_c_RE] = REE_solve(OMEGA_0_RE, OMEGA_c_RE, A, C, invA0, k_y, disc);
[T_0_RE, T_L_RE, T_s_RE, T_c_RE, T_Ls_RE] = ALM_fun(A, C, invA0, OMEGA_0_RE, OMEGA_c_RE, k_y, disc);

idx = ir_variable_indices();
n = size(T_L_RE, 1);

% Two transparent shock-timing conventions. The first is directly comparable
% to Dynare's oo_.irfs fields: period 1 is the impact response to eps_x.
% The second reproduces the legacy code's habit of placing the same shock in
% column 2, useful if you want to inspect old impulse-response indexing.
reds_impact = zeros(n, H);
reds_shifted = zeros(n, H + 1);
reds_impact(:, 1) = T_s_RE;
reds_shifted(:, 2) = T_s_RE;
for t = 2:H, reds_impact(:, t) = T_L_RE * reds_impact(:, t-1); end
for t = 3:H+1, reds_shifted(:, t) = T_L_RE * reds_shifted(:, t-1); end

%% Minimal numeric comparison on the shared IRF variables
reds_row.rk = idx.rk;
reds_row.wage = idx.wage;
reds_row.output = idx.output;
reds_row.hours = idx.hours;
reds_row.consumption = idx.consumption;
reds_row.investment = idx.investment;
reds_row.capital = idx.capital;
reds_row.gamma_x = idx.gamma_x;

max_abs_diff = zeros(numel(v), 1);
for j = 1:numel(v)
    name = v{j};
    max_abs_diff(j) = max(abs(dynare_irfs.(name) - reds_impact(reds_row.(name), 1:H).'));
end
comparison = table(string(v(:)), max_abs_diff, ...
    'VariableNames', {'variable', 'max_abs_diff'});

fprintf('\nInputs:\n');
fprintf('  x_ir_default = [%s]\n', num2str(x_ir_default, ' %.8g'));
fprintf('  x_used       = [%s]\n', num2str(x, ' %.8g'));
fprintf('  Dynare eps_H = %.8g\n', dynare_eps_H);
fprintf('\nMax abs Dynare vs REDS/SOLDS differences, using reds_impact timing:\n');
disp(comparison);
