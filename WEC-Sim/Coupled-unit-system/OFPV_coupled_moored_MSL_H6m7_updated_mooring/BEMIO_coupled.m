%% ============================================================
%  BEMIO: Convert coupled-unit Capytaine output to WEC-Sim .h5
%  ============================================================
% Methodology based on the WEC-Sim examples and documentation:
% https://wec-sim.github.io/WEC-Sim/
clear; clc; close all;

%% ============================================================
%  USER PATHS
%  ============================================================

% Set this to the location of your own local WEC-Sim installation.
wecSimPath = '...path_to_WEC-Sim';

caseDir = fileparts(mfilename('fullpath'));

% hydroData folder inside the case folder
hydroDataDir = fullfile(caseDir, 'hydroData');

% Capytaine .nc file inside hydroData

capytaineNcFile = fullfile(hydroDataDir, 'two_body_capytaine.nc');
outputH5File    = fullfile(hydroDataDir, 'coupled_unit_hydrodynamic_data');

hydrostaticsSubfolder = fullfile(hydroDataDir, 'hydrostatics');

%% ============================================================
%  ADD WEC-SIM TO MATLAB PATH
%  ============================================================

if exist(fullfile(wecSimPath, 'addWecSimSource.m'), 'file')
    addpath(genpath(wecSimPath));
    run(fullfile(wecSimPath, 'addWecSimSource.m'));

elseif exist(fullfile(wecSimPath, 'source', 'addWecSimSource.m'), 'file')
    addpath(genpath(fullfile(wecSimPath, 'source')));
    run(fullfile(wecSimPath, 'source', 'addWecSimSource.m'));

else
    error(['Could not find addWecSimSource.m. Checked:' newline ...
           fullfile(wecSimPath, 'addWecSimSource.m') newline ...
           fullfile(wecSimPath, 'source', 'addWecSimSource.m')]);
end

rehash toolboxcache;

%% ============================================================
%  CHECK BASIC FILES
%  ============================================================

if ~exist(caseDir, 'dir')
    error('Case folder does not exist: %s', caseDir);
end

if ~exist(hydroDataDir, 'dir')
    error('hydroData folder does not exist: %s', hydroDataDir);
end

if ~exist(capytaineNcFile, 'file')
    error('Capytaine NetCDF file does not exist: %s', capytaineNcFile);
end

%% ============================================================
%  PUT HYDROSTATIC FILES DIRECTLY NEXT TO THE .NC FILE
%
%  Your readCAPYTAINE.m uses:
%       [base_dir, name, ~] = fileparts(filename);
%
%  If no third argument is passed, it searches in base_dir.
%  Therefore all needed files must be directly inside hydroData.
%  ============================================================

% Files expected directly in hydroData
requiredHydroFiles = {
    'Hydrostatics.dat'
    'KH.dat'
    'Hydrostatics_0.dat'
    'KH_0.dat'
    'Hydrostatics_1.dat'
    'KH_1.dat'
};

for i = 1:length(requiredHydroFiles)

    targetFile = fullfile(hydroDataDir, requiredHydroFiles{i});
    sourceFile = fullfile(hydrostaticsSubfolder, requiredHydroFiles{i});

    if ~exist(targetFile, 'file')
        if exist(sourceFile, 'file')
            copyfile(sourceFile, targetFile);
        else
            warning('Could not find %s in hydroData or hydroData/hydrostatics.', requiredHydroFiles{i});
        end
    end

end

%% ============================================================
%  FINAL FILE CHECKS
%  ============================================================

disp('============================================================')
disp('BEMIO CAPYTAINE TO WEC-SIM H5 PATH CHECK')
disp('============================================================')

disp('WEC-Sim path:')
disp(wecSimPath)

disp('Case folder:')
disp(caseDir)

disp('hydroData folder:')
disp(hydroDataDir)

disp('Capytaine NetCDF file:')
disp(capytaineNcFile)
disp(['Exists: ', num2str(exist(capytaineNcFile, 'file'))])

disp('readCAPYTAINE function being used:')
which readCAPYTAINE

disp('Files directly inside hydroData:')
dir(hydroDataDir)

disp('Checking required hydrostatic files directly inside hydroData:')

for i = 1:length(requiredHydroFiles)
    thisFile = fullfile(hydroDataDir, requiredHydroFiles{i});
    disp([requiredHydroFiles{i}, ' exists: ', num2str(exist(thisFile, 'file'))])
end

disp('============================================================')

%% ============================================================
%  HARD OPEN CHECK FOR BASE FILES
%  ============================================================

[fileID, msg] = fopen(fullfile(hydroDataDir, 'Hydrostatics.dat'), 'r');
if fileID == -1
    error('Cannot open Hydrostatics.dat: %s', msg);
else
    fclose(fileID);
end

[fileID, msg] = fopen(fullfile(hydroDataDir, 'KH.dat'), 'r');
if fileID == -1
    error('Cannot open KH.dat: %s', msg);
else
    fclose(fileID);
end

%% ============================================================
%  READ CAPYTAINE OUTPUT
%
%  IMPORTANT:
%  Do NOT pass hydrostaticsDir as third argument here.
%  Your readCAPYTAINE.m appends the third argument to base_dir,
%  so passing a full path breaks the path.
%  ============================================================

hydro = struct();

hydro = readCAPYTAINE(hydro, capytaineNcFile);

%% ============================================================
%  SET OUTPUT H5 FILE
%  ============================================================

hydro.file = outputH5File;

%% ============================================================
%  CALCULATE IMPULSE RESPONSE FUNCTIONS
%  ============================================================

hydro = radiationIRF(hydro, [], [], [], [], []);
hydro = excitationIRF(hydro, [], [], [], [], []);

%% ============================================================
%  OPTIONAL STATE-SPACE RADIATION MODEL
%  If this errors, comment this line out and rerun.
%  ============================================================

hydro = radiationIRFSS(hydro, [], []);

%% ============================================================
%  WRITE WEC-SIM H5 FILE
%  ============================================================

writeBEMIOH5(hydro);

%% ============================================================
%  OPTIONAL BEMIO PLOTS
%  ============================================================

plotBEMIO(hydro);

%% ============================================================
%  FINAL CHECK
%  ============================================================

disp('============================================================')
disp('Finished writing WEC-Sim H5 file:')
disp(outputH5File)
disp(['H5 exists: ', num2str(exist(outputH5File, 'file'))])
disp('============================================================')