function model = load_ep_ee_dynare_model(sigma)
%% LOAD_EP_EE_DYNARE_MODEL Load the canonical EE model at explicit sigma.

assert(isnumeric(sigma) && isscalar(sigma) && isfinite(sigma) && sigma>0, ...
    'EPEE:InvalidSigma','sigma must be positive and finite.');
source_path=fullfile(fileparts(mfilename('fullpath')),'ep_ee_paper.mod');
source=fileread(source_path);
pattern='sigma=1; eps_H=0.0001;';
replacement=sprintf('sigma=%.17g; eps_H=0.0001;',sigma);
assert(count(source,pattern)==1,'EPEE:SigmaTemplateMismatch', ...
    'The canonical EE model must contain exactly one sigma calibration token.');
rendered=strrep(source,pattern,replacement);
work=tempname;
mkdir(work);
cleanup=onCleanup(@() rmdir(work,'s'));
rendered_path=fullfile(work,'ep_ee_rendered.mod');
fid=fopen(rendered_path,'w');
assert(fid>=0,'EPEE:RenderFailure','Could not create temporary Dynare model.');
file_cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'%s',rendered);
clear file_cleanup
model=load_dynare_71_linear_model(rendered_path);
assert(abs(model.calibration.sigma-sigma)<1e-14, ...
    'EPEE:SigmaOverrideFailure','Dynare did not use the requested sigma.');
model.name='Eusepi-Preston paper EE';
model.calibration.requested_sigma=sigma;
end
