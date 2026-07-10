function verify_fixture_manifest()
%% VERIFY_FIXTURE_MANIFEST Refuse silently changed characterization fixtures.

root = fileparts(fileparts(mfilename('fullpath')));
manifest = fixture_manifest();
for j = 1:numel(manifest.files)
    path = fullfile(root, manifest.files(j).name);
    assert(isfile(path), 'Missing characterization fixture: %s', path);
    if ispc
        error('Fixture SHA-256 verification is not implemented on Windows.');
    end
    [status, output] = system(sprintf('shasum -a 256 "%s"', path));
    assert(status == 0, 'Could not hash fixture: %s', path);
    actual = extractBefore(strtrim(output), 65);
    assert(strcmp(actual, manifest.files(j).sha256), ...
        'Fixture changed without an explicit manifest update: %s', path);
end
fprintf('Fixture manifest verification passed.\n');
end
