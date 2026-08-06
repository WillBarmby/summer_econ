classdef TestArtifactReporting < matlab.unittest.TestCase
    %% TESTARTIFACTREPORTING Specify pure artifact reporting consumers.

    methods (Test)
        function reportsNamedNativePath(testCase)
            artifact = scalar_artifact();
            specification = scalar_reporting_specification("path");

            report = report_artifact(artifact,specification);

            testCase.verifyEqual(report.series_names,"y");
            testCase.verifyEqual(report.horizons,0:3);
            testCase.verifyEqual(report.values,[0 1 0.5 -0.75]);
            testCase.verifyEqual(report.source,"path");
        end

        function reportsPairedIRF(testCase)
            artifact = scalar_artifact();
            artifact.simulation_result = struct( ...
                'training',struct(), ...
                'baseline',struct(), ...
                'shocked',struct(), ...
                'irf',[0 2 1], ...
                'status',"completed", ...
                'termination',struct());
            specification = scalar_reporting_specification("irf");

            report = report_artifact(artifact,specification);

            testCase.verifyEqual(report.values,[0 2 1]);
            testCase.verifyEqual(report.horizons,0:2);
        end

        function restoresLevelWithCumulativeNamedVariable(testCase)
            artifact = scalar_artifact();
            artifact.model.variable_names = {'output','gamma_x'};
            artifact.simulation_result.path = [0 1 1;0 0.1 0.2];
            series = struct( ...
                'name',"output_level", ...
                'variable',"output", ...
                'cumulative_variables',{{'gamma_x'}}, ...
                'scale',1);
            specification = reporting_specification("path",series);

            report = report_artifact(artifact,specification);

            testCase.verifyEqual(report.values,[0 1.1 1.3], ...
                'AbsTol',1e-12);
        end

        function rejectsUnknownReportedVariable(testCase)
            artifact = scalar_artifact();
            specification = scalar_reporting_specification("path");
            specification.series.variable = "unknown";

            testCase.verifyError(@() report_artifact(artifact,specification), ...
                'AdaptiveLearning:InvalidReportingSpecification');
        end

        function graphConsumesArtifactWithoutSaving(testCase)
            artifact = scalar_artifact();
            specification = scalar_reporting_specification("path");

            figure_handle = generate_artifact_figure(artifact,specification);
            cleanup = onCleanup(@() close(figure_handle)); %#ok<NASGU>

            lines = findobj(figure_handle,'Type','line');
            testCase.verifyNumElements(lines,1);
            testCase.verifyEqual(lines.XData,0:3);
            testCase.verifyEqual(lines.YData,[0 1 0.5 -0.75]);
            testCase.verifyEqual(string(figure_handle.Visible),"off");
        end
    end
end

function artifact = scalar_artifact()
model = testsupport.scalar_structural_model();
learning = testsupport.scalar_learning_specification();
experiment = testsupport.scalar_experiment_specification();
result = run_experiment(testsupport.scalar_learning_system(),experiment);
artifact = assemble_artifact(model,learning,experiment,result);
end

function specification = scalar_reporting_specification(source)
series = struct( ...
    'name',"y", ...
    'variable',"y", ...
    'cumulative_variables',{{}}, ...
    'scale',1);
specification = reporting_specification(source,series);
end

function specification = reporting_specification(source,series)
specification = struct( ...
    'source',source, ...
    'series',series, ...
    'title',"Scalar response", ...
    'x_label',"Period", ...
    'y_label',"Deviation");
end
