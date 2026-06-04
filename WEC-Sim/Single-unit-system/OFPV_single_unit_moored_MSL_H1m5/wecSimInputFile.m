%% WEC-SIM input file
% Methodology based on the WEC-Sim examples and documentation:
% https://wec-sim.github.io/WEC-Sim/

%% Simulation Data
simu = simulationClass();               % Initialize Simulation Class
simu.simMechanicsFile = 'single_OFPV_wecsim.slx';      % Specify Simulink Model File
simu.mode = 'normal';                   % Specify Simulation Mode ('normal','accelerator','rapid-accelerator')
simu.explorer = 'on';                   % Turn SimMechanics Explorer (on/off)
simu.startTime = 0;                     % Simulation Start Time [s]
simu.rampTime = 20;                     % Wave Ramp Time [s]
simu.endTime = 200;                     % Simulation End Time [s]
simu.dt = 0.02; 					    % Simulation time-step [s]
% simu.paraview.option    = 1;          %currently not working

% % Regular Waves  
waves = waveClass('regular');           % Initialize Wave Class and Specify Type                                 
waves.height = 1.5;                     % Wave Height [m]
waves.period = 7;                       % Wave Period [s]
waves.direction = 0;                    % Wave direciton [degrees]
waves.waterDepth = 30;                % Water level [m]
%% Body Data
% Float
body(1) = bodyClass('hydroData/single_unit_hydrodynamic_data.h5');       
body(1).geometryFile = 'geometry/single_OFPV_mesh.stl';    % Location of Geomtry File
body(1).mass = 89600;               % [kg] input equilibrium = displaced volume                  
 
body(1).centerGravity = [0 0 4.1];
body(1).inertia = [7935000 7935000 12069000];  % Moment of Inertia [kg*m^2]     
body(1).initial.displacement = [0 0 -4.7];     % initial draft
%% Mooring
% Moordyn
mooring(1) = mooringClass('mooring');       	% Initialize mooringClass
mooring(1).moorDyn = 1;                         % Initialize MoorDyn
mooring(1).moorDynLines = 8;                	% Specify number of lines
mooring(1).moorDynNodes = [51 51 51 51 51 51 51 51];       	% Specify number of nodes per line