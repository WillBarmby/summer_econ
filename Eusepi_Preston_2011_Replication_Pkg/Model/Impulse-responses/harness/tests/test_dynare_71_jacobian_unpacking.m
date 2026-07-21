function test_dynare_71_jacobian_unpacking()
%% TEST_DYNARE_71_JACOBIAN_UNPACKING Pin Dynare's derivative layout.

M=struct('endo_nbr',2,'exo_nbr',1,'exo_det_nbr',0,'eq_nbr',2, ...
    'lead_lag_incidence',[1 0;2 3;0 4]);
lag=[11 0;12 0];
current=[21 22;23 24];
lead=[0 31;0 32];
shock=[-41;-42];
matrices=unpack_dynare_71_jacobian([lag current lead shock],M);
assert(isequal(matrices.lag,lag));
assert(isequal(matrices.current,current));
assert(isequal(matrices.lead,lead));
assert(isequal(matrices.shock,shock));
fprintf('Dynare 7.1 Jacobian lag/current/lead/shock layout test passed.\n');
end
