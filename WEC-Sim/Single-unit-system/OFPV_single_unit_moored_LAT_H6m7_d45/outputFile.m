%%Output wec-sim results
%
%
% Methodology based on the WEC-Sim examples and documentation:
% https://wec-sim.github.io/WEC-Sim/

clc;

%% ===================== USER SETTINGS =====================

% Case name used in exported file names
caseName = 'LAT_H6p7_d45';

caseDir = fileparts(mfilename('fullpath'));

% Results output folder inside the case folder
resultsFolder = fullfile(caseDir, 'ResultsOutput');

% Body number to export
bodyNum = 1;
tStart = 40;     % [s]
tEnd   = 180;     % [s]

% Editable plot titles
surgePlotTitle = 'Surge motion, LAT, H = 6.7 m';
swayPlotTitle  = 'Sway motion, LAT, H = 6.7 m';
heavePlotTitle = 'Heave motion, LAT, H = 6.7 m';
rollPlotTitle  = 'Roll motion, LAT, H = 6.7 m';
pitchPlotTitle = 'Pitch motion, LAT, H = 6.7 m';
yawPlotTitle   = 'Yaw motion, LAT, H = 6.7 m';

surgeExcPlotTitle = 'Surge excitation force, LAT, H = 6.7 m';
heaveExcPlotTitle = 'Heave excitation force, LAT, H = 6.7 m';
pitchExcPlotTitle = 'Pitch excitation moment, LAT, H = 6.7 m';

% Figure saving options
saveFigures = true;
savePNG     = true;
saveFIG     = true;
closeFiguresAfterSaving = false;

% Plot appearance
plotLineWidth = 1.4;
fontSize      = 12;

%% ===================== BASIC CHECKS =====================

if ~exist(resultsFolder, 'dir')
    mkdir(resultsFolder);
end

if ~exist('output', 'var')
    error('The variable "output" does not exist in the MATLAB workspace. Run wecSim first, then run this script.');
end

if ~isprop(output, 'bodies') && ~isfield_safe(output, 'bodies')
    error('The variable "output" does not contain output.bodies.');
end

if length(output.bodies) < bodyNum
    error('Body number %d does not exist. output.bodies only contains %d body/bodies.', bodyNum, length(output.bodies));
end

bodyObj = output.bodies(bodyNum);

%% ===================== EXTRACT MOTION DATA =====================

if ~has_field_or_property(bodyObj, 'time')
    error('output.bodies(%d).time does not exist.', bodyNum);
end

if ~has_field_or_property(bodyObj, 'position')
    error('output.bodies(%d).position does not exist.', bodyNum);
end

if ~has_field_or_property(bodyObj, 'velocity')
    error('output.bodies(%d).velocity does not exist.', bodyNum);
end

if ~has_field_or_property(bodyObj, 'acceleration')
    error('output.bodies(%d).acceleration does not exist.', bodyNum);
end

t   = get_field_or_property(bodyObj, 'time');
pos = get_field_or_property(bodyObj, 'position');
vel = get_field_or_property(bodyObj, 'velocity');
acc = get_field_or_property(bodyObj, 'acceleration');

t = t(:);

if size(pos,2) < 6 || size(vel,2) < 6 || size(acc,2) < 6
    error('Position, velocity, or acceleration arrays do not contain 6 DOF columns.');
end

if length(t) ~= size(pos,1)
    error('Time vector length does not match the number of rows in output.bodies(%d).position.', bodyNum);
end

%% ===================== SELECT TIME WINDOW =====================

idxWindow = t >= tStart & t <= tEnd;

if ~any(idxWindow)
    error('No data found between tStart = %.2f s and tEnd = %.2f s.', tStart, tEnd);
end

tPlot   = t(idxWindow);
posPlot = pos(idxWindow,:);
velPlot = vel(idxWindow,:);
accPlot = acc(idxWindow,:);

%% ===================== CONVERT 6DOF MOTION VARIABLES =====================

% Position
surge = posPlot(:,1);              % [m]
sway  = posPlot(:,2);              % [m]
heave = posPlot(:,3);              % [m]
roll  = posPlot(:,4) * 180/pi;     % [deg]
pitch = posPlot(:,5) * 180/pi;     % [deg]
yaw   = posPlot(:,6) * 180/pi;     % [deg]

% Velocity
surgeVel = velPlot(:,1);           % [m/s]
swayVel  = velPlot(:,2);           % [m/s]
heaveVel = velPlot(:,3);           % [m/s]
rollVel  = velPlot(:,4) * 180/pi;  % [deg/s]
pitchVel = velPlot(:,5) * 180/pi;  % [deg/s]
yawVel   = velPlot(:,6) * 180/pi;  % [deg/s]

% Acceleration
surgeAcc = accPlot(:,1);           % [m/s^2]
swayAcc  = accPlot(:,2);           % [m/s^2]
heaveAcc = accPlot(:,3);           % [m/s^2]
rollAcc  = accPlot(:,4) * 180/pi;  % [deg/s^2]
pitchAcc = accPlot(:,5) * 180/pi;  % [deg/s^2]
yawAcc   = accPlot(:,6) * 180/pi;  % [deg/s^2]

%% ===================== EXPORT 6DOF MOTION TABLE =====================

Tmotion = table( ...
    tPlot, ...
    surge, sway, heave, roll, pitch, yaw, ...
    surgeVel, swayVel, heaveVel, rollVel, pitchVel, yawVel, ...
    surgeAcc, swayAcc, heaveAcc, rollAcc, pitchAcc, yawAcc, ...
    'VariableNames', { ...
    'time_s', ...
    'surge_m', 'sway_m', 'heave_m', 'roll_deg', 'pitch_deg', 'yaw_deg', ...
    'surgeVel_mps', 'swayVel_mps', 'heaveVel_mps', 'rollVel_degps', 'pitchVel_degps', 'yawVel_degps', ...
    'surgeAcc_mps2', 'swayAcc_mps2', 'heaveAcc_mps2', 'rollAcc_degps2', 'pitchAcc_degps2', 'yawAcc_degps2'});

motionExcelFile = fullfile(resultsFolder, [caseName '_6DOF_motion_' num2str(tStart) 'to' num2str(tEnd) 's.xlsx']);
motionMatFile   = fullfile(resultsFolder, [caseName '_6DOF_motion_' num2str(tStart) 'to' num2str(tEnd) 's.mat']);

writetable(Tmotion, motionExcelFile);
save(motionMatFile, 'Tmotion', 'tPlot', 'posPlot', 'velPlot', 'accPlot');

%% ===================== EXPORT 6DOF MOTION SUMMARY =====================

TmotionSummary = table( ...
    max(abs(surge)), rms(surge), ...
    max(abs(sway)),  rms(sway), ...
    max(abs(heave)), rms(heave), ...
    max(abs(roll)),  rms(roll), ...
    max(abs(pitch)), rms(pitch), ...
    max(abs(yaw)),   rms(yaw), ...
    'VariableNames', { ...
    'surgeMax_m', 'surgeRMS_m', ...
    'swayMax_m', 'swayRMS_m', ...
    'heaveMax_m', 'heaveRMS_m', ...
    'rollMax_deg', 'rollRMS_deg', ...
    'pitchMax_deg', 'pitchRMS_deg', ...
    'yawMax_deg', 'yawRMS_deg'});

motionSummaryExcelFile = fullfile(resultsFolder, [caseName '_6DOF_motion_summary_' num2str(tStart) 'to' num2str(tEnd) 's.xlsx']);
motionSummaryMatFile   = fullfile(resultsFolder, [caseName '_6DOF_motion_summary_' num2str(tStart) 'to' num2str(tEnd) 's.mat']);

writetable(TmotionSummary, motionSummaryExcelFile);
save(motionSummaryMatFile, 'TmotionSummary');

%% ===================== EXTRACT EXCITATION FORCE/MOMENT =====================

hasExcitation = has_field_or_property(bodyObj, 'forceExcitation');

if hasExcitation
    Fexc = get_field_or_property(bodyObj, 'forceExcitation');

    if isempty(Fexc)
        warning('output.bodies(%d).forceExcitation exists but is empty. Excitation export skipped.', bodyNum);
        hasExcitation = false;
    elseif size(Fexc,2) < 6
        warning('output.bodies(%d).forceExcitation does not contain 6 columns. Excitation export skipped.', bodyNum);
        hasExcitation = false;
    elseif size(Fexc,1) ~= length(t)
        warning('forceExcitation row count does not match the time vector length. Excitation export skipped.');
        hasExcitation = false;
    end
else
    warning('output.bodies(%d).forceExcitation does not exist. Excitation export skipped.', bodyNum);
end

if hasExcitation

    FexcPlot = Fexc(idxWindow,:);

    % Excitation force/moment components
    surgeExcForce  = FexcPlot(:,1);     % [N]
    swayExcForce   = FexcPlot(:,2);     % [N]
    heaveExcForce  = FexcPlot(:,3);     % [N]
    rollExcMoment  = FexcPlot(:,4);     % [N.m]
    pitchExcMoment = FexcPlot(:,5);     % [N.m]
    yawExcMoment   = FexcPlot(:,6);     % [N.m]

    Texcitation = table( ...
        tPlot, ...
        surgeExcForce, swayExcForce, heaveExcForce, ...
        rollExcMoment, pitchExcMoment, yawExcMoment, ...
        surgeExcForce/1000, swayExcForce/1000, heaveExcForce/1000, ...
        rollExcMoment/1000, pitchExcMoment/1000, yawExcMoment/1000, ...
        'VariableNames', { ...
        'time_s', ...
        'surgeExc_N', 'swayExc_N', 'heaveExc_N', ...
        'rollExc_Nm', 'pitchExc_Nm', 'yawExc_Nm', ...
        'surgeExc_kN', 'swayExc_kN', 'heaveExc_kN', ...
        'rollExc_kNm', 'pitchExc_kNm', 'yawExc_kNm'});

    excitationExcelFile = fullfile(resultsFolder, [caseName '_excitation_force_moment_' num2str(tStart) 'to' num2str(tEnd) 's.xlsx']);
    excitationMatFile   = fullfile(resultsFolder, [caseName '_excitation_force_moment_' num2str(tStart) 'to' num2str(tEnd) 's.mat']);

    writetable(Texcitation, excitationExcelFile);
    save(excitationMatFile, 'Texcitation', 'FexcPlot');

    TexcitationSummary = table( ...
        max(abs(surgeExcForce)),  rms(surgeExcForce), ...
        max(abs(heaveExcForce)),  rms(heaveExcForce), ...
        max(abs(pitchExcMoment)), rms(pitchExcMoment), ...
        max(abs(surgeExcForce))/1000,  rms(surgeExcForce)/1000, ...
        max(abs(heaveExcForce))/1000,  rms(heaveExcForce)/1000, ...
        max(abs(pitchExcMoment))/1000, rms(pitchExcMoment)/1000, ...
        'VariableNames', { ...
        'surgeExcMax_N', 'surgeExcRMS_N', ...
        'heaveExcMax_N', 'heaveExcRMS_N', ...
        'pitchExcMax_Nm', 'pitchExcRMS_Nm', ...
        'surgeExcMax_kN', 'surgeExcRMS_kN', ...
        'heaveExcMax_kN', 'heaveExcRMS_kN', ...
        'pitchExcMax_kNm', 'pitchExcRMS_kNm'});

    excitationSummaryExcelFile = fullfile(resultsFolder, [caseName '_excitation_summary_' num2str(tStart) 'to' num2str(tEnd) 's.xlsx']);
    excitationSummaryMatFile   = fullfile(resultsFolder, [caseName '_excitation_summary_' num2str(tStart) 'to' num2str(tEnd) 's.mat']);

    writetable(TexcitationSummary, excitationSummaryExcelFile);
    save(excitationSummaryMatFile, 'TexcitationSummary');

end

%% ===================== PLOT SETTINGS =====================

set(0, 'DefaultAxesFontSize', fontSize);
set(0, 'DefaultLineLineWidth', plotLineWidth);

%% ===================== 6DOF MOTION PLOTS =====================

make_clean_plot(tPlot, surge, ...
    'Time [s]', 'Surge [m]', surgePlotTitle, ...
    tStart, tEnd, resultsFolder, [caseName '_surge_motion_' num2str(tStart) 'to' num2str(tEnd) 's'], ...
    saveFigures, savePNG, saveFIG, closeFiguresAfterSaving);

make_clean_plot(tPlot, sway, ...
    'Time [s]', 'Sway [m]', swayPlotTitle, ...
    tStart, tEnd, resultsFolder, [caseName '_sway_motion_' num2str(tStart) 'to' num2str(tEnd) 's'], ...
    saveFigures, savePNG, saveFIG, closeFiguresAfterSaving);

make_clean_plot(tPlot, heave, ...
    'Time [s]', 'Heave [m]', heavePlotTitle, ...
    tStart, tEnd, resultsFolder, [caseName '_heave_motion_' num2str(tStart) 'to' num2str(tEnd) 's'], ...
    saveFigures, savePNG, saveFIG, closeFiguresAfterSaving);

make_clean_plot(tPlot, roll, ...
    'Time [s]', 'Roll [deg]', rollPlotTitle, ...
    tStart, tEnd, resultsFolder, [caseName '_roll_motion_' num2str(tStart) 'to' num2str(tEnd) 's'], ...
    saveFigures, savePNG, saveFIG, closeFiguresAfterSaving);

make_clean_plot(tPlot, pitch, ...
    'Time [s]', 'Pitch [deg]', pitchPlotTitle, ...
    tStart, tEnd, resultsFolder, [caseName '_pitch_motion_' num2str(tStart) 'to' num2str(tEnd) 's'], ...
    saveFigures, savePNG, saveFIG, closeFiguresAfterSaving);

make_clean_plot(tPlot, yaw, ...
    'Time [s]', 'Yaw [deg]', yawPlotTitle, ...
    tStart, tEnd, resultsFolder, [caseName '_yaw_motion_' num2str(tStart) 'to' num2str(tEnd) 's'], ...
    saveFigures, savePNG, saveFIG, closeFiguresAfterSaving);

%% ===================== EXCITATION FORCE/MOMENT PLOTS =====================

if hasExcitation

    make_clean_plot(tPlot, surgeExcForce/1000, ...
        'Time [s]', 'Surge excitation force [kN]', surgeExcPlotTitle, ...
        tStart, tEnd, resultsFolder, [caseName '_surge_excitation_force_' num2str(tStart) 'to' num2str(tEnd) 's'], ...
        saveFigures, savePNG, saveFIG, closeFiguresAfterSaving);

    make_clean_plot(tPlot, heaveExcForce/1000, ...
        'Time [s]', 'Heave excitation force [kN]', heaveExcPlotTitle, ...
        tStart, tEnd, resultsFolder, [caseName '_heave_excitation_force_' num2str(tStart) 'to' num2str(tEnd) 's'], ...
        saveFigures, savePNG, saveFIG, closeFiguresAfterSaving);

    make_clean_plot(tPlot, pitchExcMoment/1000, ...
        'Time [s]', 'Pitch excitation moment [kN m]', pitchExcPlotTitle, ...
        tStart, tEnd, resultsFolder, [caseName '_pitch_excitation_moment_' num2str(tStart) 'to' num2str(tEnd) 's'], ...
        saveFigures, savePNG, saveFIG, closeFiguresAfterSaving);

end

%% ===================== DISPLAY CONFIRMATION =====================

disp(' ');
disp('============================================================');
disp('WEC-Sim motion and excitation results exported successfully.');
disp('============================================================');
disp(['Case name: ', caseName]);
disp(['Selected time window: ', num2str(tStart), ' s to ', num2str(tEnd), ' s']);
disp(['Results folder: ', resultsFolder]);
disp(' ');
disp(['6DOF motion Excel: ', motionExcelFile]);
disp(['6DOF motion summary Excel: ', motionSummaryExcelFile]);

if hasExcitation
    disp(['Excitation Excel: ', excitationExcelFile]);
    disp(['Excitation summary Excel: ', excitationSummaryExcelFile]);
else
    disp('Excitation force/moment was not exported because forceExcitation was unavailable or invalid.');
end

disp('============================================================');

%% ===================== LOCAL FUNCTIONS =====================

function tf = has_field_or_property(obj, name)
    if isstruct(obj)
        tf = isfield(obj, name);
    else
        tf = isprop(obj, name);
    end
end

function val = get_field_or_property(obj, name)
    if isstruct(obj)
        val = obj.(name);
    else
        val = obj.(name);
    end
end

function tf = isfield_safe(obj, name)
    if isstruct(obj)
        tf = isfield(obj, name);
    else
        tf = false;
    end
end

function make_clean_plot(xData, yData, xLabelText, yLabelText, plotTitleText, ...
    xStart, xEnd, resultsFolder, fileBaseName, saveFigures, savePNG, saveFIG, closeAfterSaving)

    fig = figure('Color', 'w');
    plot(xData, yData, 'LineWidth', 1.4);

    xlabel(xLabelText);
    ylabel(yLabelText);
    title(plotTitleText, 'Interpreter', 'none');

    grid on;
    box on;
    xlim([xStart xEnd]);

    ax = gca;
    ax.FontSize = 12;
    ax.LineWidth = 1.0;

    if saveFigures
        if savePNG
            saveas(fig, fullfile(resultsFolder, [fileBaseName '.png']));
        end

        if saveFIG
            savefig(fig, fullfile(resultsFolder, [fileBaseName '.fig']));
        end
    end

    if closeAfterSaving
        close(fig);
    end

end