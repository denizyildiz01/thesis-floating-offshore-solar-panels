%% ============================================================
%  BEMIO: Convert single-unit Capytaine output to WEC-Sim .h5
%  ============================================================
% Methodology based on the WEC-Sim examples and documentation:
% https://wec-sim.github.io/WEC-Sim/

clear; clc; close all;

%% Paths
% Set this to the location of your own local WEC-Sim installation.
wecSimPath = '...path_to_WEC-Sim';

caseDir = fileparts(mfilename('fullpath'));

% hydroData folder inside the case folder
hydroDataDir = fullfile(caseDir, 'hydroData');

% Capytaine .nc file inside hydroData
capytaineNcFile = fullfile(hydroDataDir, 'single_unit_capytaine.nc');

% IMPORTANT:
% Do not include .h5 here. writeBEMIOH5 adds .h5 automatically.
outputH5Base = fullfile(hydroDataDir, 'single_unit');

%% Add WEC-Sim source
if exist(fullfile(wecSimPath, 'addWecSimSource.m'), 'file')
    addpath(genpath(wecSimPath));
    run(fullfile(wecSimPath, 'addWecSimSource.m'));

elseif exist(fullfile(wecSimPath, 'source', 'addWecSimSource.m'), 'file')
    addpath(genpath(fullfile(wecSimPath, 'source')));
    run(fullfile(wecSimPath, 'source', 'addWecSimSource.m'));

else
    error('Could not find addWecSimSource.m.');
end

rehash toolboxcache;

%% Checks
disp('============================================================')
disp('SINGLE-UNIT BEMIO PATH CHECK')
disp('============================================================')

disp('Capytaine file:')
disp(capytaineNcFile)
disp(['Exists: ', num2str(exist(capytaineNcFile, 'file'))])

disp('Hydrostatics.dat:')
disp(fullfile(hydroDataDir, 'Hydrostatics.dat'))
disp(['Exists: ', num2str(exist(fullfile(hydroDataDir, 'Hydrostatics.dat'), 'file'))])

disp('KH.dat:')
disp(fullfile(hydroDataDir, 'KH.dat'))
disp(['Exists: ', num2str(exist(fullfile(hydroDataDir, 'KH.dat'), 'file'))])

disp('readCAPYTAINE function:')
which readCAPYTAINE

disp('============================================================')

%% Read Capytaine data
hydro = struct();

% Do not pass third argument for your current readCAPYTAINE version.
% It will look for Hydrostatics.dat and KH.dat in the same folder as the .nc.
hydro = readCAPYTAINE(hydro, capytaineNcFile);

%% Set output h5 base name
hydro.file = outputH5Base;

%% Compute IRFs
hydro = radiationIRF(hydro, [], [], [], [], []);
hydro = excitationIRF(hydro, [], [], [], [], []);

%% Optional state-space radiation model
% If this gives an error, comment it out and rerun.
hydro = radiationIRFSS(hydro, [], []);

%% Write H5
writeBEMIOH5(hydro);

%% Optional plots
plotBEMIO(hydro);

disp('============================================================')
disp('Finished writing:')
disp([outputH5Base, '.h5'])
disp(['H5 exists: ', num2str(exist([outputH5Base, '.h5'], 'file'))])
disp('============================================================')