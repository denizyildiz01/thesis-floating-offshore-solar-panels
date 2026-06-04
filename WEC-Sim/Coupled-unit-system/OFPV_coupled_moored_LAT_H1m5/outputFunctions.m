%% userDefinedFunctions.m
% Post-processing file for two-body coupled OFPV WEC-Sim model.
% This file is automatically called by WEC-Sim after the simulation.

fprintf('\nRunning double-body post-processing...\n');

%% ------------------------------------------------------------------------
%  Case configuration
% -------------------------------------------------------------------------
% Change only these values for each simulation case.

waterLevel = 'LAT';      % Example: 'LAT', 'HAT'
waveHeight = 1.5;        % Wave height [m], example: 1.5 or 6
caseName   = 'coupled';  % Example: 'coupled', 'coupled_45deg', etc.

waveHeightText = strrep(num2str(waveHeight), '.', 'p');

folderName = sprintf('%s_h%s_%s', waterLevel, waveHeightText, caseName);

% Folder where this .m file is located
caseDir = fileparts(mfilename('fullpath'));

% ResultsOutput folder inside the case folder
baseDir = fullfile(caseDir, 'ResultsOutput');

% Post-processing folder for this simulation case
postDir = fullfile(baseDir, folderName);

if ~exist(postDir, 'dir')
    mkdir(postDir);
end

fprintf('Results will be saved in:\n%s\n', postDir);

%% ------------------------------------------------------------------------
%  Basic checks
% -------------------------------------------------------------------------
if ~exist('output', 'var')
    error('The WEC-Sim output object does not exist in the workspace.');
end

nBodies = length(output.bodies);

if nBodies < 2
    warning('Only %d body found in output. This file is written for 2 bodies.', nBodies);
end

bodyNamesDisplay = {'Body 1', 'Body 2'};
bodyNamesFile    = {'body1', 'body2'};
dofNames         = {'surge', 'sway', 'heave', 'roll', 'pitch', 'yaw'};

%% ------------------------------------------------------------------------
%  Save complete WEC-Sim output object
% -------------------------------------------------------------------------
save(fullfile(postDir, 'wecSimOutput_double_body.mat'), 'output');

fprintf('Saved complete output object.\n');

%% ------------------------------------------------------------------------
%  Extract and save body motion data
% -------------------------------------------------------------------------
for iBody = 1:min(nBodies, 2)

    t   = output.bodies(iBody).time;
    pos = output.bodies(iBody).position;
    vel = output.bodies(iBody).velocity;
    acc = output.bodies(iBody).acceleration;

    motionData = table();

    motionData.time = t;

    for iDof = 1:6
        motionData.(['pos_' dofNames{iDof}]) = pos(:, iDof);
        motionData.(['vel_' dofNames{iDof}]) = vel(:, iDof);
        motionData.(['acc_' dofNames{iDof}]) = acc(:, iDof);
    end

    fileName = sprintf('%s_motion.csv', bodyNamesFile{iBody});
    writetable(motionData, fullfile(postDir, fileName));

    fprintf('Saved motion data for %s: %s\n', bodyNamesDisplay{iBody}, fileName);
end

%% ------------------------------------------------------------------------
%  Plot body motions: body 1 and body 2
% -------------------------------------------------------------------------
for iBody = 1:min(nBodies, 2)

    t   = output.bodies(iBody).time;
    pos = output.bodies(iBody).position;

    fig = figure('Name', sprintf('%s motions', bodyNamesDisplay{iBody}), 'Color', 'w');

    for iDof = 1:6
        subplot(3, 2, iDof)
        plot(t, pos(:, iDof), 'LineWidth', 1.2)
        grid on
        xlabel('Time [s]')
        ylabel(dofNames{iDof})
        title(sprintf('%s - %s', bodyNamesDisplay{iBody}, dofNames{iDof}), ...
            'Interpreter', 'none')
    end

    sgtitle(sprintf('Motion response of %s', bodyNamesDisplay{iBody}), ...
        'Interpreter', 'none');

    saveas(fig, fullfile(postDir, sprintf('%s_motion_response.png', bodyNamesFile{iBody})));
    savefig(fig, fullfile(postDir, sprintf('%s_motion_response.fig', bodyNamesFile{iBody})));

end

%% ------------------------------------------------------------------------
%  Plot comparison between body 1 and body 2
% -------------------------------------------------------------------------
if nBodies >= 2

    t1 = output.bodies(1).time;
    t2 = output.bodies(2).time;

    pos1 = output.bodies(1).position;
    pos2 = output.bodies(2).position;

    for iDof = 1:6

        fig = figure('Name', sprintf('Comparison %s', dofNames{iDof}), 'Color', 'w');

        plot(t1, pos1(:, iDof), 'LineWidth', 1.2)
        hold on
        plot(t2, pos2(:, iDof), '--', 'LineWidth', 1.2)

        grid on
        xlabel('Time [s]')
        ylabel(dofNames{iDof})
        title(sprintf('Body comparison - %s', dofNames{iDof}), ...
            'Interpreter', 'none')
        legend('Body 1', 'Body 2', 'Location', 'best')

        saveas(fig, fullfile(postDir, sprintf('comparison_%s.png', dofNames{iDof})));
        savefig(fig, fullfile(postDir, sprintf('comparison_%s.fig', dofNames{iDof})));

    end
end

%% ------------------------------------------------------------------------
%  Relative motion between body 2 and body 1
% -------------------------------------------------------------------------
if nBodies >= 2

    t = output.bodies(1).time;

    pos1 = output.bodies(1).position;
    pos2 = output.bodies(2).position;

    relPos = pos2 - pos1;

    relativeData = table();
    relativeData.time = t;

    for iDof = 1:6
        relativeData.(['relative_' dofNames{iDof}]) = relPos(:, iDof);
    end

    writetable(relativeData, fullfile(postDir, 'relative_motion_body2_minus_body1.csv'));

    fig = figure('Name', 'Relative motions', 'Color', 'w');

    for iDof = 1:6
        subplot(3, 2, iDof)
        plot(t, relPos(:, iDof), 'LineWidth', 1.2)
        grid on
        xlabel('Time [s]')
        ylabel(['Delta ' dofNames{iDof}], 'Interpreter', 'none')
        title(sprintf('Relative %s', dofNames{iDof}), ...
            'Interpreter', 'none')
    end

    sgtitle('Relative motion: Body 2 minus Body 1', ...
        'Interpreter', 'none');

    saveas(fig, fullfile(postDir, 'relative_motion_body2_minus_body1.png'));
    savefig(fig, fullfile(postDir, 'relative_motion_body2_minus_body1.fig'));

end

%% ------------------------------------------------------------------------
%  Built-in WEC-Sim force plots for both bodies
% -------------------------------------------------------------------------
% DOF numbers:
% 1 = surge
% 2 = sway
% 3 = heave
% 4 = roll
% 5 = pitch
% 6 = yaw

try
    for iBody = 1:min(nBodies, 2)
        for iDof = 1:6

            output.plotForces(iBody, iDof);

            fig = gcf;

            % Fix possible title/label interpreter issues
            set(findall(fig, '-property', 'Interpreter'), 'Interpreter', 'none');

            saveas(fig, fullfile(postDir, ...
                sprintf('%s_forces_%s.png', bodyNamesFile{iBody}, dofNames{iDof})));
            savefig(fig, fullfile(postDir, ...
                sprintf('%s_forces_%s.fig', bodyNamesFile{iBody}, dofNames{iDof})));

        end
    end
catch ME
    warning('Could not create WEC-Sim force plots: %s', ME.message);
end

%% ------------------------------------------------------------------------
%  Built-in WEC-Sim response plots for both bodies
% -------------------------------------------------------------------------
try
    for iBody = 1:min(nBodies, 2)
        for iDof = 1:6

            output.plotResponse(iBody, iDof);

            fig = gcf;

            % Fix possible title/label interpreter issues
            set(findall(fig, '-property', 'Interpreter'), 'Interpreter', 'none');

            saveas(fig, fullfile(postDir, ...
                sprintf('%s_response_%s.png', bodyNamesFile{iBody}, dofNames{iDof})));
            savefig(fig, fullfile(postDir, ...
                sprintf('%s_response_%s.fig', bodyNamesFile{iBody}, dofNames{iDof})));

        end
    end
catch ME
    warning('Could not create WEC-Sim response plots: %s', ME.message);
end

%% ------------------------------------------------------------------------
%  MoorDyn output check
% -------------------------------------------------------------------------
% MoorDyn is normally loaded by WEC-Sim during post-processing.
% This section only checks whether mooring data exists in the output object.

try
    if isprop(output, 'mooring')
        fprintf('Mooring output detected in WEC-Sim output object.\n');
    else
        fprintf('No mooring property detected directly in output object.\n');
        fprintf('Use the MoorDyn Lines.out files separately if needed.\n');
    end
catch
    fprintf('Could not check mooring output structure.\n');
end

%% ------------------------------------------------------------------------
%  Summary values
% -------------------------------------------------------------------------
summaryFile = fullfile(postDir, 'summary_double_body.txt');
fid = fopen(summaryFile, 'w');

fprintf(fid, 'Double-body WEC-Sim post-processing summary\n');
fprintf(fid, '==========================================\n\n');

fprintf(fid, 'Case configuration\n');
fprintf(fid, '------------------\n');
fprintf(fid, 'Water level : %s\n', waterLevel);
fprintf(fid, 'Wave height : %.3f m\n', waveHeight);
fprintf(fid, 'Case name   : %s\n', caseName);
fprintf(fid, 'Output folder:\n%s\n\n', postDir);

fprintf(fid, 'Number of bodies in output: %d\n\n', nBodies);

for iBody = 1:min(nBodies, 2)

    pos = output.bodies(iBody).position;

    fprintf(fid, '%s\n', bodyNamesDisplay{iBody});
    fprintf(fid, 'Maximum absolute motions:\n');

    for iDof = 1:6
        fprintf(fid, '  %-6s : %.6g\n', dofNames{iDof}, max(abs(pos(:, iDof))));
    end

    fprintf(fid, '\n');
end

if nBodies >= 2

    relPos = output.bodies(2).position - output.bodies(1).position;

    fprintf(fid, 'Relative motion: Body 2 minus Body 1\n');
    fprintf(fid, 'Maximum absolute relative motions:\n');

    for iDof = 1:6
        fprintf(fid, '  %-6s : %.6g\n', dofNames{iDof}, max(abs(relPos(:, iDof))));
    end

end

fclose(fid);

fprintf('Saved summary file:\n%s\n', summaryFile);

fprintf('\nDouble-body post-processing completed.\n');