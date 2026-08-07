function value = artifact_file_sha256(file)
%% ARTIFACT_FILE_SHA256 Hash file bytes for sidecar integrity checks.
handle=fopen(file,'rb');
if handle<0, error('AdaptiveLearning:InvalidArtifactFile','Cannot read artifact file.'); end
cleanup=onCleanup(@() fclose(handle)); %#ok<NASGU>
bytes=fread(handle,Inf,'*uint8');
digest=java.security.MessageDigest.getInstance('SHA-256'); digest.update(bytes);
hash=typecast(digest.digest(),'uint8');
value=lower(string(reshape(dec2hex(hash,2).',1,[])));
end
