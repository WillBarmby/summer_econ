function steady_state = calculate_model_steady_state(sigma, calibration, rbc_dummy, participation)
%% CALCULATE_MODEL_STEADY_STATE Build steady-state ratios and derived coefficients.

delta = calibration.delta;
alpha = calibration.alpha;
gamma = calibration.gamma;
eps_H = calibration.eps_H;
beta = calibration.beta;

if participation ~= 0
    error('calculate_model_steady_state:UnsupportedParticipation', ...
        'The participation specification has not been implemented.');
end

%% Paramters of the capital production function
delta_tilda = 1-(1-delta)/gamma; %% investment to capital ratio

beta_tilda = beta*gamma^(1-sigma); %% modified discount rate

%% Steady State values of main variables

theta = (gamma*beta_tilda^(-1)-(1-delta))/delta;

if rbc_dummy == 0
    u_ss = 1;
else
    u_ss = (theta*delta)^(1/theta); %% capital utilization
end

yk_ratio = delta*theta/(alpha*gamma);
ik_ratio = delta_tilda;
ck_ratio = yk_ratio-ik_ratio;
cy_ratio = ck_ratio/yk_ratio;
R_bar = beta^(-1)-(1-delta)/gamma^(sigma); % Will — does not appear to be used anywhere
delta_s = (1-delta)/gamma;
R_tilda = beta_tilda^(-1)-delta_s;
psi = cy_ratio^(-1)*(1-alpha);

%% coeffs. convolutions of parameters

eps_c = ck_ratio+(eps_H-psi*(sigma-1)/sigma)^(-1)*R_tilda*(1-alpha)/alpha;
eps_w = (1+(eps_H-psi*(sigma-1)/sigma)^(-1))*R_tilda*(1-alpha)/alpha;
chi = psi*(1-sigma)/(sigma*eps_H+psi*(1-sigma));
c_c = (1-beta_tilda)*(1-chi)/eps_c;

steady_state = struct();
steady_state.delta_tilda = delta_tilda;
steady_state.beta_tilda = beta_tilda;
steady_state.theta = theta;
steady_state.u_ss = u_ss;
steady_state.yk_ratio = yk_ratio;
steady_state.ik_ratio = ik_ratio;
steady_state.ck_ratio = ck_ratio;
steady_state.cy_ratio = cy_ratio;
steady_state.R_bar = R_bar;
steady_state.delta_s = delta_s;
steady_state.R_tilda = R_tilda;
steady_state.psi = psi;
steady_state.eps_c = eps_c;
steady_state.eps_w = eps_w;
steady_state.chi = chi;
steady_state.c_c = c_c;

end
