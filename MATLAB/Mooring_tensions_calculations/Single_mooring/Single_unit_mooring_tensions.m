%% Plot MoorDyn fairlead tensions from lines.out
% Methodology based on MoorDyn V2: Hall, M. (2020), "MoorDyn V2: New capabilities in mooring system components and load cases."

clear; clc; close all;

%% User settings

% Folder containing lines.out
scriptFolder = fileparts(mfilename('fullpath'));
resultsFolder = fullfile(scriptFolder, 'LAT_H6m7');

% Name of the MoorDyn output file
fileName = 'lines.out';

% Full path to lines.out
filePath = fullfile(resultsFolder, fileName);

% Time range to show
tStart = 40;      % [s]
tEnd   = 180;     % [s]

% Unit of input tension values in lines.out
dataUnit = 'N';

% Mooring line MBL
MBL_kN = 670;                 % [kN]
limit70_kN = 0.70 * MBL_kN;   % [kN]

% Optional output figure name
saveFigure = true;
figureName = fullfile(resultsFolder, 'mooringtensionLAT_H6m7.png');

%% Read numeric data from lines.out

% The first row contains text headers, so skip it.
data = readmatrix(filePath, ...
    'FileType', 'text', ...
    'NumHeaderLines', 1);

% Remove possible empty/NaN rows
data = data(~all(isnan(data), 2), :);

% Basic check
if size(data, 2) < 9
    error('The file does not contain at least 9 numeric columns. Check the lines.out format.');
end

% Column 1 is time, columns 2:9 are fairlead tensions
time = data(:, 1);
Traw = data(:, 2:9);

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

fig = figure('Color', 'w', 'Position', [100 100 1300 750]);
hold on; grid on; box on;

lineHandles = gobjects(nLines, 1);

for iLine = 1:nLines
    lineHandles(iLine) = plot(timeCrop, TCrop_kN(:, iLine), ...
        'LineWidth', 1.3, ...
        'DisplayName', sprintf('Line %d', iLine));
end

% Horizontal MBL line
yline(MBL_kN, '--', ...
    sprintf('MBL = %.0f kN', MBL_kN), ...
    'LineWidth', 1.8, ...
    'LabelHorizontalAlignment', 'left', ...
    'LabelVerticalAlignment', 'bottom');

% Horizontal 70% MBL line
yline(limit70_kN, ':', ...
    sprintf('70%% MBL = %.0f kN', limit70_kN), ...
    'LineWidth', 1.8, ...
    'LabelHorizontalAlignment', 'left', ...
    'LabelVerticalAlignment', 'bottom');

% Mark and label peak values
for iLine = 1:nLines
    plot(peakTimes_s(iLine), peakVals_kN(iLine), 'o', ...
        'MarkerSize', 6, ...
        'LineWidth', 1.4, ...
        'HandleVisibility', 'off');

    text(peakTimes_s(iLine), peakVals_kN(iLine), ...
        sprintf('  %.1f kN', peakVals_kN(iLine)), ...
        'FontSize', 8, ...
        'VerticalAlignment', 'bottom', ...
        'HandleVisibility', 'off');
end

xlabel('Time [s]', 'Interpreter', 'latex');
ylabel('Mooring tension [kN]', 'Interpreter', 'latex');

title(sprintf('Fairlead tensions at LAT, H = 6.7 m, %.0f--%.0f s', tStart, tEnd), ...
    'Interpreter', 'latex');

legend(lineHandles, 'Location', 'eastoutside');

xlim([tStart tEnd]);

% Give vertical space above the largest relevant value
yMaxPlot = max([max(TCrop_kN, [], 'all'), MBL_kN]) * 1.10;
ylim([0 yMaxPlot]);

set(gca, 'FontSize', 11);

%% Print peak table in Command Window

fprintf('\nPeak fairlead tensions between %.1f s and %.1f s:\n', tStart, tEnd);
fprintf('---------------------------------------------------------------\n');
fprintf('%10s %15s %15s %15s\n', 'Line', 'Peak [kN]', 'Time [s]', 'Peak/MBL [%]');
fprintf('---------------------------------------------------------------\n');

for iLine = 1:nLines
    fprintf('%10d %15.3f %15.3f %15.2f\n', ...
        iLine, ...
        peakVals_kN(iLine), ...
        peakTimes_s(iLine), ...
        100 * peakVals_kN(iLine) / MBL_kN);
end

fprintf('---------------------------------------------------------------\n');
fprintf('MBL      = %.3f kN\n', MBL_kN);
fprintf('70%% MBL  = %.3f kN\n\n', limit70_kN);

%% Save figure

if saveFigure
    exportgraphics(fig, figureName, 'Resolution', 300);
    fprintf('Figure saved as:\n%s\n', figureName);
end