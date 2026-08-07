function fingerprint = innovation_fingerprint(values)
%% INNOVATION_FINGERPRINT Stable SHA-256 pairing evidence for numeric draws.

bytes = typecast([uint64(size(values,1)) uint64(size(values,2)) ...
    typecast(values(:).','uint64')],'uint8');
digest = java.security.MessageDigest.getInstance('SHA-256');
digest.update(bytes);
hash = typecast(digest.digest(),'uint8');
fingerprint = lower(string(reshape(dec2hex(hash,2).',1,[])));
end
