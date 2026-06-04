%% Mooring line design workflow
% Method based on:
% - DNV-OS-E301: Position mooring
% - DNV-OS-E303: Offshore fibre ropes
clear; clc;

%% ------------------------------------------------------------
% 1. Parameters
% ------------------------------------------------------------

rho_w   = 1025;      % seawater density [kg/m3]
rho_air = 1.225;     % air density [kg/m3]
g       = 9.81;      % gravity [m/s2]

%% ------------------------------------------------------------
% 2. Initial conditions
% ------------------------------------------------------------

h_ext = 33.4;         % HAT+H  global reference water depth [m]
h_low = 26.8;         % LAT-H lowest operational water depth [m]

Tc_0 = 3;             % static draft [m]
Fc_0 = 7;             % staic freeboard [m]

fairlead_tolerance = 0.30;          % fairlead position above bottom [m]
zf_0 = -Tc_0 + fairlead_tolerance;  % initial fairlead z-position relative to h [m]

% Buoyancy/freeboard design limits

h_extra_max_m = 3;       % maximum allowed operational extra buoyancy height [m]
F_reserve_min_m = 0.6;  % minimum freeboard after mooring [m]

%% ------------------------------------------------------------
% 3. Structure dimensions for environmental loads
% ------------------------------------------------------------

Nc = 4;              % number of floaters [-]
Dc = 3.0;            % floater diameter [m]

Dvert = 0.3556;      % diameter of vertical structure [m]
Hvert = 4.0;         % exposed height of vertical structure [m]
Bp    = 20.0;        % platform width facing wind [m]
tp    = 0.3556;      % vertical height platform [m]

%% ------------------------------------------------------------
% 4. Load coefficients
% ------------------------------------------------------------

Cd_wind    = 0.6;    % wind drag/shape coefficient [-]
Cd_current = 0.6;    % current drag coefficient [-]
Cd_wave    = 0.6;    % Morison drag coefficient [-]
Cm_wave    = 2.0;    % Morison inertia coefficient [-]

%% ------------------------------------------------------------
% 5. Environmental cases
% ------------------------------------------------------------

% Operational worst case
OP.Hs    = 1.5;      % significant wave height [m]
OP.Tp    = 6.0;      % wave period [s]
OP.Uwind = 28.1;     % wind speed [m/s]
OP.Vc    = 1.24;     % current speed [m/s]
OP.h     = h_low;    % water depth [m]

% Extreme case
EXT.Hs    = 6.7;     % significant wave height [m]
EXT.Tp    = 12.0;    % wave period [s]
EXT.Uwind = 28.1;    % wind speed [m/s]
EXT.Vc    = 1.24;    % current speed [m/s]
EXT.h     = h_ext;   % water depth [m]

%% ------------------------------------------------------------
% 6. Mooring and material inputs
% ------------------------------------------------------------

Nlines = 8;                  % total number of mooring lines [-]
n_eff  = 2;                  % lines effectively resisting load direction [-]

alpha_deg_list = 10:1:89;    % installation angle from horizontal [deg]
Lmax_m = 66;                 % maximum allowed stretched line length [m]

util_limit = 0.70;           % <= util_limit * MBL

materialName = "Polyester";  % material
% Material data taken from Weller et al. (2015).
% Source:
% Weller, S. D., Johanning, L., Davies, P., and Banfield, S. J. (2015).
% Synthetic mooring ropes for marine renewable energy applications.
% Renewable Energy, 83, 1268--1278.

sigma_tensile_MPa = 1050;    % tensile strength [MPa = N/mm2]
E_GPa = 11;                  % Young's modulus [GPa]
rho_rope = 1380;             % material density [kg/m3]

% Manufacturer data taken from Lankhorst Offshore.
% Reference:
% Lankhorst Offshore. Deepwater mooring. Technical report / product brochure.
% Available from: https://www.lankhorstoffshore.com
d_min_manufacturer_mm = 40;  % minimum available manufacturer rope diameter [mm]
MBL_manufacturer_kN = 670;   % selected manufacturer rope MBL/MBF [kN]
eps_max_pct = 1.4;           % elongation limit 70% of 2% maximum curve value [%]

%% ------------------------------------------------------------
% 7. Optimization
% ------------------------------------------------------------
%   - best solution is selected using weight:
%       Score = 0.5*(Ls/Lmax) + 0.5*(h_extra/h_extra_max)

tol_Ls_m      = 1e-4;        % convergence tolerance for Ls [m]
tol_h_extra_m = 1e-4;        % convergence tolerance for h_extra [m]
maxIter       = 50;          % safety limit to avoid infinite loop

w_L = 0.5;                   % weight for normalized line length
w_h = 0.5;                   % weight for normalized buoyancy height

%% ------------------------------------------------------------
% 8. Pre-calculations
% ------------------------------------------------------------

sigma_Npm2 = sigma_tensile_MPa * 1e6;    % [N/m2]
E_Npm2     = E_GPa * 1e9;                % [N/m2]

A_waterplane = Nc * pi * Dc^2 / 4;       % waterplane area [m2]

nAngles = numel(alpha_deg_list);

%% ------------------------------------------------------------
% 9. Allocate result arrays
% ------------------------------------------------------------

Angle_deg       = zeros(nAngles,1);
Iterations      = zeros(nAngles,1);
Converged       = false(nAngles,1);

Draft_final_m     = zeros(nAngles,1);
Freeboard_final_m = zeros(nAngles,1);
zf_final_m        = zeros(nAngles,1);

F_OP_total_kN   = zeros(nAngles,1);
F_EXT_total_kN  = zeros(nAngles,1);

Ls_OP_m         = zeros(nAngles,1);
L0_OP_m         = zeros(nAngles,1);
Ranchor_OP_m    = zeros(nAngles,1);

T_OP_kN         = zeros(nAngles,1);
T_EXT_kN        = zeros(nAngles,1);

MBL_req_kN      = zeros(nAngles,1);
d_eq_mm         = zeros(nAngles,1);
d_used_mm       = zeros(nAngles,1);
eps_OP_pct      = zeros(nAngles,1);
EA_used_kN      = zeros(nAngles,1);

Fz_total_OP_kN  = zeros(nAngles,1);
Vextra_OP_m3    = zeros(nAngles,1);
h_extra_OP_m    = zeros(nAngles,1);

Score           = inf(nAngles,1);

LengthPass      = false(nAngles,1);
NoSlackPass     = false(nAngles,1);
DiameterPass    = false(nAngles,1);
ElongationPass  = false(nAngles,1);
BuoyancyPass    = false(nAngles,1);
FreeboardPass   = false(nAngles,1);
StrengthPass    = false(nAngles,1);

% Final environmental load components from the extreme load case [kN]
Fwind_kN        = zeros(nAngles,1);
Fcurrent_kN     = zeros(nAngles,1);
Fwave_kN        = zeros(nAngles,1);

%% ------------------------------------------------------------
% 10. Optimization loop over installation angle
% ------------------------------------------------------------

bestScore = inf;
bestIndex = NaN;

for i = 1:nAngles

    alpha_deg = alpha_deg_list(i);
    alpha = deg2rad(alpha_deg);

    % Initial iteration values
    h_extra_old = 0.0;              % extra height of the floater, draft increases
    Ls_old = NaN;
    converged_i = false;

    % Variables to store final converged values for this angle
    final = struct();

    for iter = 1:maxIter

        % ----------------------------------------------------
        % Update geometry from current estimated pull-down
        % ----------------------------------------------------
        draft_iter = Tc_0 + h_extra_old;              % increased draft due to pull-down [m]
        freeboard_iter = Fc_0 - h_extra_old;          % remaining freeboard [m]
        freeboard_for_wind = max(freeboard_iter, 0);  % avoid negative exposed area

        % Fairlead is fixed to the floater: 30 cm above bottom
        zf_iter = -draft_iter + fairlead_tolerance;

        % ----------------------------------------------------
        % Recalculate environmental projected areas
        % ----------------------------------------------------
        A_wind = Nc*Dc*freeboard_for_wind + Nc*Dvert*Hvert + Bp*tp;
        A_current = Nc*Dc*draft_iter;

        % ----------------------------------------------------
        % Recalculate environmental loads with updated geometry
        % ----------------------------------------------------
        F_OP  = envLoad(OP,  A_wind, A_current, rho_air, rho_w, ...
                        Cd_wind, Cd_current, Cd_wave, Cm_wave, Nc, Dc, draft_iter, g);

        F_EXT = envLoad(EXT, A_wind, A_current, rho_air, rho_w, ...
                        Cd_wind, Cd_current, Cd_wave, Cm_wave, Nc, Dc, draft_iter, g);

        % ----------------------------------------------------
        % Mooring geometry
        % ----------------------------------------------------
        H_OP = h_low + zf_iter;     % fairlead-to-seabed vertical distance [m]

        if H_OP <= 0
            break
        end

        Ls = H_OP / sin(alpha);
        Ranchor = H_OP / tan(alpha);

        % ----------------------------------------------------
        % Mooring line tensions
        % ----------------------------------------------------
        T_OP  = F_OP.Ftotal_kN  / (n_eff*cos(alpha));
        T_EXT = F_EXT.Ftotal_kN / (n_eff*cos(alpha));

        % ----------------------------------------------------
        % Strength and diameter estimate
        % ----------------------------------------------------
        MBL_req = T_EXT / util_limit;

        A_req = (MBL_req*1000) / sigma_Npm2;
        d_eq = sqrt(4*A_req/pi);       % [m]
        d_eq_temp_mm = d_eq*1000;      % [mm]

        d_used_temp_mm = max(d_eq_temp_mm, d_min_manufacturer_mm);
        d_used_m = d_used_temp_mm / 1000;

        A_used = pi*d_used_m^2/4;
        EA_N = E_Npm2*A_used;
        EA_kN = EA_N/1000;

        % ----------------------------------------------------
        % Operational elongation and unstretched length
        % ----------------------------------------------------
        eps_OP = (T_OP*1000) / EA_N;
        L0 = Ls / (1 + eps_OP);

        % ----------------------------------------------------
        % Operational vertical pull-down and buoyancy correction
        % ----------------------------------------------------
        Fz_total_OP = Nlines*T_OP*sin(alpha);
        Vextra_OP = 1000*Fz_total_OP/(rho_w*g);
        h_extra_new = Vextra_OP/A_waterplane;

        % ----------------------------------------------------
        % Convergence check based on Ls and h_extra
        % ----------------------------------------------------
        if iter > 1
            dLs = abs(Ls - Ls_old);
            dh  = abs(h_extra_new - h_extra_old);

            if dLs < tol_Ls_m && dh < tol_h_extra_m
                converged_i = true;
            end
        end

        % Store final/current values
        final.draft_iter = draft_iter;
        final.freeboard_iter = freeboard_iter;
        final.zf_iter = zf_iter;
        final.F_OP = F_OP;
        final.F_EXT = F_EXT;
        final.Ls = Ls;
        final.Ranchor = Ranchor;
        final.T_OP = T_OP;
        final.T_EXT = T_EXT;
        final.MBL_req = MBL_req;
        final.d_eq_temp_mm = d_eq_temp_mm;
        final.d_used_temp_mm = d_used_temp_mm;
        final.EA_kN = EA_kN;
        final.eps_OP_pct = eps_OP*100;
        final.L0 = L0;
        final.Fz_total_OP = Fz_total_OP;
        final.Vextra_OP = Vextra_OP;
        final.h_extra = h_extra_new;

        if converged_i
            break
        end

        % Update values for next iteration
        Ls_old = Ls;
        h_extra_old = h_extra_new;
    end

    % --------------------------------------------------------
    % Store angle result
    % --------------------------------------------------------
    Angle_deg(i)         = alpha_deg;
    Iterations(i)        = iter;
    Converged(i)         = converged_i;

    if isfield(final, 'Ls')

        Draft_final_m(i)     = final.draft_iter;
        Freeboard_final_m(i) = final.freeboard_iter;
        zf_final_m(i)        = final.zf_iter;

        F_OP_total_kN(i)     = final.F_OP.Ftotal_kN;
        F_EXT_total_kN(i)    = final.F_EXT.Ftotal_kN;

        Ls_OP_m(i)           = final.Ls;
        L0_OP_m(i)           = final.L0;
        Ranchor_OP_m(i)      = final.Ranchor;

        T_OP_kN(i)           = final.T_OP;
        T_EXT_kN(i)          = final.T_EXT;

        MBL_req_kN(i)        = final.MBL_req;
        d_eq_mm(i)           = final.d_eq_temp_mm;
        d_used_mm(i)         = final.d_used_temp_mm;
        eps_OP_pct(i)        = final.eps_OP_pct;
        EA_used_kN(i)        = final.EA_kN;

        Fz_total_OP_kN(i)    = final.Fz_total_OP;
        Vextra_OP_m3(i)      = final.Vextra_OP;
        h_extra_OP_m(i)      = final.h_extra;

        % Final environmental load components from the extreme load case [kN]
        Fwind_kN(i)          = final.F_EXT.Fwind_kN;
        Fcurrent_kN(i)       = final.F_EXT.Fcurrent_kN;
        Fwave_kN(i)          = final.F_EXT.Fwave_kN;

        % Pass/fail checks
        LengthPass(i)     = final.Ls <= Lmax_m;
        NoSlackPass(i)    = final.T_OP > 0;
        DiameterPass(i)   = final.d_used_temp_mm >= final.d_eq_temp_mm;
        ElongationPass(i) = final.eps_OP_pct <= eps_max_pct;
        BuoyancyPass(i)   = final.h_extra <= h_extra_max_m;
        FreeboardPass(i)  = final.freeboard_iter >= F_reserve_min_m;
        StrengthPass(i)   = final.T_EXT <= util_limit*MBL_manufacturer_kN;

        % Objective score, only meaningful for converged candidates
        Score(i) = w_L*(final.Ls/Lmax_m) + w_h*(final.h_extra/h_extra_max_m);

        FinalPass_i = Converged(i) && LengthPass(i) && NoSlackPass(i) && ...
                      DiameterPass(i) && ElongationPass(i) && ...
                      BuoyancyPass(i) && FreeboardPass(i) && StrengthPass(i);

        % Advance best solution only if current candidate is better
        if FinalPass_i && Score(i) < bestScore
            bestScore = Score(i);
            bestIndex = i;
        end
    end
end

FinalPass = Converged & LengthPass & NoSlackPass & DiameterPass & ...
            ElongationPass & BuoyancyPass & FreeboardPass & StrengthPass;

%% ------------------------------------------------------------
% 11. Results table
% ------------------------------------------------------------

results = table(Angle_deg, Iterations, Converged, ...
    Draft_final_m, Freeboard_final_m, zf_final_m, ...
    F_OP_total_kN, F_EXT_total_kN, ...
    Ls_OP_m, L0_OP_m, Ranchor_OP_m, ...
    T_OP_kN, T_EXT_kN, MBL_req_kN, ...
    d_eq_mm, d_used_mm, eps_OP_pct, EA_used_kN, ...
    Fz_total_OP_kN, Vextra_OP_m3, h_extra_OP_m, Score, ...
    LengthPass, NoSlackPass, DiameterPass, ElongationPass, ...
    BuoyancyPass, FreeboardPass, StrengthPass, FinalPass, ...
    Fwind_kN, Fcurrent_kN, Fwave_kN);

disp(results);

if ~isnan(bestIndex)
    finalSolution = results(bestIndex,:);
    fprintf('\nOptimal solution found:\n');
    disp(finalSolution);
else
    finalSolution = table();
    fprintf('\nNo passing optimal solution found. Check limits or input assumptions.\n');
end

%% ------------------------------------------------------------
% 12. Export results to folder
% ------------------------------------------------------------
scriptFolder = fileparts(mfilename('fullpath'));
outputFolder = fullfile(scriptFolder, 'Synthetic_mooring_iteration', 'Mooring_Solution');

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

csvFileAll  = fullfile(outputFolder, 'synthetic_rope_optimized_all_results.csv');
xlsxFile    = fullfile(outputFolder, 'synthetic_rope_optimized_results.xlsx');

writetable(results, csvFileAll);
writetable(results, xlsxFile, 'Sheet', 'AllConvergedAngles');

if ~isempty(finalSolution)
    csvFileBest = fullfile(outputFolder, 'synthetic_rope_optimal_solution.csv');
    writetable(finalSolution, csvFileBest);
    writetable(finalSolution, xlsxFile, 'Sheet', 'OptimalSolution');
end

fprintf('Results exported to:\n%s\n%s\n', csvFileAll, xlsxFile);

%% ============================================================
% Local functions
% ============================================================

function F = envLoad(env, A_wind, A_current, rho_air, rho_w, ...
                     Cd_wind, Cd_current, Cd_wave, Cm_wave, ...
                     Nc, Dc, draft, g)

    F.Fwind_kN = 0.5*rho_air*Cd_wind*A_wind*env.Uwind^2/1000;

    F.Fcurrent_kN = 0.5*rho_w*Cd_current*A_current*env.Vc^2/1000;

    F.Fwave_kN = morisonWaveForce(env.Hs, env.Tp, env.h, draft, Dc, ...
                                  Nc, env.Vc, rho_w, Cd_wave, Cm_wave, g);

    F.Ftotal_kN = F.Fwind_kN + F.Fcurrent_kN + F.Fwave_kN;
end

function Fwave_kN = morisonWaveForce(H, T, h, draft, D, Ncyl, Vc, rho, Cd, Cm, g)

    omega = 2*pi/T;

    dispersion = @(k) g*k.*tanh(k*h) - omega^2;
    k = fzero(dispersion, [1e-6, 10]);

    % Representative depth: mid-draft
    zmid = -draft/2;

    u = omega*H/2 * cosh(k*(zmid+h)) / sinh(k*h);
    a = omega^2*H/2 * cosh(k*(zmid+h)) / sinh(k*h);

    A = pi*D^2/4;

    F_drag_total   = 0.5*rho*Cd*D*draft*(Vc + u)*abs(Vc + u);
    F_drag_current = 0.5*rho*Cd*D*draft*Vc*abs(Vc);
    F_inertia      = rho*Cm*A*draft*a;

    Fwave_kN = Ncyl*(F_drag_total - F_drag_current + F_inertia)/1000;
end