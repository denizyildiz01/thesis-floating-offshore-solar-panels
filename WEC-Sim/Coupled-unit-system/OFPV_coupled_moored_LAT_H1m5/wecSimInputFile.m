%% WEC-SIM input file
% Methodology based on the WEC-Sim examples and documentation:
% https://wec-sim.github.io/WEC-Sim/

%% Simulation Data
simu = simulationClass();               % Initialize Simulation Class
simu.simMechanicsFile = 'coupled_OFPV_wecsim.slx';      % Specify Simulink Model File
simu.mode = 'normal';                   % Specify Simulation Mode ('normal','accelerator','rapid-accelerator')
simu.explorer = 'on';                   % Turn SimMechanics Explorer (on/off)
simu.startTime = 0;                     % Simulation Start Time [s]
simu.rampTime = 20;                     % Wave Ramp Time [s]
simu.endTime = 200;                     % Simulation End Time [s]
simu.dt = 0.02; 							% Simulation time-step [s]
% Paraview export on = 1
simu.paraview.option = 0;

% % Regular Waves  
waves = waveClass('regular');           % Initialize Wave Class and Specify Type                                 
waves.height = 1.5;                     % Wave Height [m]
waves.period = 7;                       % Wave Period [s]
waves.direction = 0;                    % Wave Period [s]
waves.waterDepth = 28.1;                % Water level [m]
%% Body data
% Both bodies use the same coupled hydrodynamic h5 file
% generated from the two-body Capytaine run.
body(1) = bodyClass('hydroData/coupled_unit_hydrodynamic_data.h5');
body(1).geometryFile = 'geometry/coupled_OFPV_body1.stl';
body(1).name = '1st_Unit';
body(1).mass = 89600;   % [kg]
body(1).centerGravity = [0 0 4.1];
body(1).inertia = [7935000 7935000 12069000];
body(1).initial.displacement = [0 0 0];
% Body 2
body(2) = bodyClass('hydroData/coupled_unit_hydrodynamic_data.h5');
body(2).geometryFile = 'geometry/coupled_OFPV_body2.stl';
body(2).name = '2nd_Unit';
body(2).mass = 89600;   % [kg]
body(2).centerGravity =[0 0 4.1];
body(2).inertia = [7935000 7935000 12069000];
body(2).initial.displacement = [0 0 0];

% Marker joint location
waves.marker.location = [12.85, 0 ];
waves.marker.style = 1;
waves.marker.size = 15;
waves.marker.graphicColor = [1 0 0];


%% Mooring for MoorDynConnection1
mooring(1) = mooringClass('mooring1');
mooring(1).moorDyn = 1;
mooring(1).moorDynLines = 6;
mooring(1).moorDynNodes = 21 * ones(1,6);
%% Mooring for MoorDynConnection2
mooring(2) = mooringClass('mooring2');
mooring(2).moorDyn = 1;
mooring(2).moorDynLines = 6;
mooring(2).moorDynNodes = 21 * ones(1,6);