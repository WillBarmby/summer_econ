function matrices = unpack_dynamic_jacobian(jacobian,M)
%% UNPACK_DYNAMIC_JACOBIAN Restore dense timing blocks in declaration order.

n = M.endo_nbr;
q = M.exo_nbr;
if M.exo_det_nbr~=0 || ~isequal(size(jacobian),[M.eq_nbr 3*n+q])
    error('AdaptiveLearning:JacobianLayout', ...
        'Dynare returned an unsupported analytical Jacobian layout.');
end
incidence = zeros(3,n);
if size(M.lead_lag_incidence,2)~=n || size(M.lead_lag_incidence,1)>3
    error('AdaptiveLearning:TimingLayout', ...
        'Only one lag and one lead are supported.');
end
incidence(1:size(M.lead_lag_incidence,1),:) = M.lead_lag_incidence;
phase = cell(3,1);
for p = 1:3
    phase{p} = jacobian(:,(p-1)*n+(1:n));
    inactive = incidence(p,:)==0;
    if any(abs(phase{p}(:,inactive))>=1e-12,'all')
        error('AdaptiveLearning:JacobianLayout', ...
            'Dynare returned derivatives for inactive timing entries.');
    end
end
matrices = struct('lag',phase{1},'current',phase{2}, ...
    'lead',phase{3},'shock',jacobian(:,3*n+(1:q)));
end
