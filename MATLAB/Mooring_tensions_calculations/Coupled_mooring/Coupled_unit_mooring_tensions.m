%% Plot MoorDyn fairlead tensions from lines.out
% Methodology based on MoorDyn V2: Hall, M. (2020), "MoorDyn V2: New capabilities in mooring system components and load cases."

clear; clc; close all;

% Folder containing lines.out
scriptFolder = fileparts(mfilename('fullpath'));
resultsFolder = fullfile(scriptFolder, 'c_MSL_H6m7_updated_mooring');
% Name of the MoorDyn output file
fileName = 'lines.out';

% Full path to lines.out
filePath = fullfile(resultsFolder, fileName);

% Time range to show
tStart = 40;      % [s]
tEnd   = 180;     % [s]

% Unit of the tension values in lines.out
% Use 'N' if the file gives tension in Newton
% Use 'kN' if the file already gives tension in kN
dataUnit = 'N';

% Mooring line MBL
MBL_kN = 1310;                 % [kN]
limit70_kN = 0.70 * MBL_kN;   % [kN]

% Optional output figure name
saveFigure = true;
figureName = fullfile(resultsFolder, 'coupled_mooring_tensions_updated.png');

%% Read numeric data from lines.out

% The first row contains text headers, so skip it.
data = readmatrix(filePath, ...
    'FileType', 'text', ...
    'NumHeaderLines', 1);

% Remove possible empty/NaN rows
data = data(~all(isnan(data), 2), :);

% Basic check
if size(data, 2) < 13
    error('The file does not contain at least 13 numeric columns. Expected time + 12 fairlead-tension columns.');
end

% Column 1 is time, columns 2:13 are fairlead tensions
time = data(:, 1);
Traw = data(:, 2:13);

nLines = size(Traw, 2);

%% Convert fairlead tensions to kN

switch lower(dataUnit)
    case 'n'
        T_kN = Traw / 1000;
    case 'kn'
        T_kN = Traw;
    otherwise
        error('Unknown dataUnit. Use either ''N'' or ''kN''.');
end

%% Crop data to selected time range

idx = time >= tStart & time <= tEnd;

timeCrop = time(idx);
TCrop_kN = T_kN(idx, :);

if isempty(timeCrop)
    error('No data found in the selected time range. Check tStart and tEnd.');
end

%% Find peak values in selected interval

peakVals_kN = zeros(1, nLines);
peakTimes_s = zeros(1, nLines);

for iLine = 1:nLines
    [peakVals_kN(iLine), idxPeak] = max(TCrop_kN(:, iLine));
    peakTimes_s(iLine) = timeCrop(idxPeak);
end

%% Plot all fairlead tensions

fig = figure('Color', 'w', 'Position', [100 100 1350 750]);
hold on; grid on; box on;

lineHandles = gobjects(nLines, 1);

% Colours for body groups
body1Color = [0.85 0.10 0.10];   % red
body2Color = [0.10 0.25 0.90];   % blue

% Slightly different line styles to distinguish lines within the same body
lineStyles = {'-', '--', ':', '-.', '-', '--'};

for iLine = 1:nLines

    if iLine <= 6
        thisColor = body1Color;
        thisBody = 1;
        localLine = iLine;
    else
        thisColor = body2Color;
        thisBody = 2;
        localLine = iLine - 6;
    end

    thisStyle = lineStyles{localLine};

    lineHandles(iLine) = plot(timeCrop, TCrop_kN(:, iLine), ...
        'LineStyle', thisStyle, ...
        'Color', thisColor, ...
        'LineWidth', 1.3, ...
        'DisplayName', sprintf('Body %d - Line %d', thisBody, localLine));
end

% Horizontal MBL line
yline(MBL_kN, 'k--', ...
    sprintf('MBL = %.0f kN', MBL_kN), ...
    'LineWidth', 1.8, ...
    'LabelHorizontalAlignment', 'left', ...
    'LabelVerticalAlignment', 'bottom');

% Horizontal 70% MBL line
yline(limit70_kN, 'k:', ...
    sprintf('70%% MBL = %.0f kN', limit70_kN), ...
    'LineWidth', 1.8, ...
    'LabelHorizontalAlignment', 'left', ...
    'LabelVerticalAlignment', 'bottom');

% Mark and label peak values
for iLine = 1:nLines

    if iLine <= 6
        thisColor = body1Color;
    else
        thisColor = body2Color;
    end

    plot(peakTimes_s(iLine), peakVals_kN(iLine), 'o', ...
        'Color', thisColor, ...
        'MarkerFaceColor', thisColor, ...
        'MarkerSize', 5.5, ...
        'LineWidth', 1.2, ...
        'HandleVisibility', 'off');

    text(peakTimes_s(iLine), peakVals_kN(iLine), ...
        sprintf('  %.1f kN', peakVals_kN(iLine)), ...
        'Color', thisColor, ...
        'FontSize', 8, ...
        'VerticalAlignment', 'bottom', ...
        'HandleVisibility', 'off');
end

xlabel('Time [s]', 'Interpreter', 'latex');
ylabel('Mooring tension [kN]', 'Interpreter', 'latex');

title(sprintf('Coupled-system fairlead tensions at MSL, H= 6.7 m'));

legend(lineHandles, 'Location', 'eastoutside');

xlim([tStart tEnd]);

% Give vertical space above the largest relevant value
yMaxPlot = max([max(TCrop_kN, [], 'all'), MBL_kN]) * 1.10;
ylim([0 yMaxPlot]);

set(gca, 'FontSize', 11);

%% Print peak table in Command Window

fprintf('\nPeak fairlead tensions between %.1f s and %.1f s:\n', tStart, tEnd);
fprintf('-------------------------------------------------------------------------\n');
fprintf('%10s %10s %15s %15s %15s\n', 'Body', 'Line', 'Peak [kN]', 'Time [s]', 'Peak/MBL [%]');
fprintf('-------------------------------------------------------------------------\n');

for iLine = 1:nLines

    if iLine <= 6
        bodyNum = 1;
        localLine = iLine;
    else
        bodyNum = 2;
        localLine = iLine - 6;
    end

    fprintf('%10d %10d %15.3f %15.3f %15.2f\n', ...
        bodyNum, ...
        localLine, ...
        peakVals_kN(iLine), ...
        peakTimes_s(iLine), ...
        100 * peakVals_kN(iLine) / MBL_kN);
end

fprintf('-------------------------------------------------------------------------\n');
fprintf('MBL      = %.3f kN\n', MBL_kN);
fprintf('70%% MBL  = %.3f kN\n\n', limit70_kN);

%% Save figure

if saveFigure
    exportgraphics(fig, figureName, 'Resolution', 300);
    fprintf('Figure saved as:\n%s\n', figureName);
end