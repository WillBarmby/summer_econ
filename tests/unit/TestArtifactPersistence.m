classdef TestArtifactPersistence < matlab.unittest.TestCase
    methods (Test)
        function writesMATAndInspectableJSON(testCase)
            [folder,artifact]=fixture(); cleanup=onCleanup(@() rmdir(folder,'s')); %#ok<NASGU>
            paths=save_artifact(fullfile(folder,'run.mat'),artifact);
            testCase.verifyTrue(isfile(paths.mat)); testCase.verifyTrue(isfile(paths.json));
            inventory=whos('-file',paths.mat);
            testCase.verifyEqual({inventory.name},{'artifact'});
            metadata=jsondecode(fileread(paths.json));
            testCase.verifyEqual(string(metadata.schema_version),"3.0");
            testCase.verifyEqual(string(metadata.kind),"single_run");
            testCase.verifyFalse(isfield(metadata,'simulation_result'));
        end
        function roundTripsCanonicalValue(testCase)
            [folder,artifact]=fixture(); cleanup=onCleanup(@() rmdir(folder,'s')); %#ok<NASGU>
            save_artifact(fullfile(folder,'run.mat'),artifact);
            testCase.verifyEqual(load_artifact(fullfile(folder,'run.mat')),artifact);
        end
        function loadsWithoutOptionalSidecar(testCase)
            [folder,artifact]=fixture(); cleanup=onCleanup(@() rmdir(folder,'s')); %#ok<NASGU>
            paths=save_artifact(fullfile(folder,'run.mat'),artifact); delete(paths.json);
            testCase.verifyEqual(load_artifact(paths.mat),artifact);
        end
        function refusesOverwriteByDefault(testCase)
            [folder,artifact]=fixture(); cleanup=onCleanup(@() rmdir(folder,'s')); %#ok<NASGU>
            file=fullfile(folder,'run.mat'); save_artifact(file,artifact);
            testCase.verifyError(@() save_artifact(file,artifact), ...
                'AdaptiveLearning:InvalidArtifactFile');
            testCase.verifyWarningFree(@() save_artifact(file,artifact,'Overwrite',true));
        end
        function detectsChecksumMismatch(testCase)
            [folder,artifact]=fixture(); cleanup=onCleanup(@() rmdir(folder,'s')); %#ok<NASGU>
            paths=save_artifact(fullfile(folder,'run.mat'),artifact);
            metadata=jsondecode(fileread(paths.json)); metadata.mat_sha256="wrong";
            write_text(paths.json,jsonencode(metadata));
            testCase.verifyError(@() load_artifact(paths.mat), ...
                'AdaptiveLearning:ArtifactIntegrityFailure');
        end
        function rejectsMalformedMATAndOldSchema(testCase)
            folder=tempname; mkdir(folder); cleanup=onCleanup(@() rmdir(folder,'s')); %#ok<NASGU>
            other=1; save(fullfile(folder,'bad.mat'),'other');
            testCase.verifyError(@() load_artifact(fullfile(folder,'bad.mat')), ...
                'AdaptiveLearning:InvalidArtifactFile');
            [~,artifact]=fixture(); artifact.schema_version="2.0";
            save(fullfile(folder,'old.mat'),'artifact');
            testCase.verifyError(@() load_artifact(fullfile(folder,'old.mat')), ...
                'AdaptiveLearning:UnsupportedArtifactSchema');
        end
    end
end
function [folder,artifact]=fixture()
folder=tempname; mkdir(folder); model=testsupport.scalar_structural_model();
learning=testsupport.scalar_learning_specification(); experiment=testsupport.scalar_experiment_specification();
result=run_experiment(testsupport.scalar_learning_system(),experiment);
artifact=assemble_artifact(model,learning,experiment,result);
end
function write_text(file,value)
handle=fopen(file,'w'); cleanup=onCleanup(@() fclose(handle)); %#ok<NASGU>
fwrite(handle,value,'char');
end
