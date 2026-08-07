classdef TestExperimentFolder < matlab.unittest.TestCase
    methods (Test)
        function runsRelocatableLocalManifest(testCase)
            root = setup_project();
            folder = fullfile(root,'examples','tiny_linear_experiment');
            before_directory = pwd;
            before_full_path = path;
            before_path = strsplit(path,pathsep);
            artifact = run_experiment_folder(folder);

            testCase.verifyEqual(string(pwd),string(before_directory));
            testCase.verifyEqual(path,before_full_path);
            testCase.verifyEqual(artifact.kind,"training_irf");
            testCase.verifyEqual(artifact.case.id,"tiny_linear");
            testCase.verifyEqual(artifact.status,"completed");
            testCase.verifyFalse(any(strcmp(strsplit(path,pathsep),folder) & ...
                ~any(strcmp(before_path,folder))));
        end

        function runsComparisonManifest(testCase)
            root = setup_project();
            artifact = run_experiment_folder(fullfile( ...
                root,'experiments','ep_comparison'));

            testCase.verifyEqual(artifact.kind,"comparison");
            testCase.verifyEqual(numel(artifact.cases),2);
            testCase.verifyEqual(artifact.cases{1}.case.id,"ep_ee");
            testCase.verifyEqual(artifact.cases{2}.case.id,"ep_ih");
            testCase.verifyEqual(artifact.status,"completed");
        end

        function rejectsMalformedManifest(testCase)
            folder = tempname;
            mkdir(folder);
            cleanup = onCleanup(@() rmdir(folder,'s')); %#ok<NASGU>
            file = fopen(fullfile(folder,'experiment.m'),'w');
            testCase.verifyGreaterThan(file,0);
            fprintf(file,'function manifest = experiment(), manifest = struct(); end\n');
            fclose(file);

            testCase.verifyError(@() run_experiment_folder(folder), ...
                'AdaptiveLearning:InvalidExperimentManifest');
        end

        function rejectsFolderWithoutManifest(testCase)
            root = setup_project();
            testCase.verifyError(@() run_experiment_folder( ...
                fullfile(root,'tests','fixtures')), ...
                'AdaptiveLearning:InvalidExperimentManifest');
        end
    end
end
