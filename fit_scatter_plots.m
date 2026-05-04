%% --- Scatter Plots Of Independent And Dependent Variables ---
clear; close all; clc;

% -- Grab data -- 
addpath('/Users/parkerwilkerson/Desktop/test_data/GPS/analyzed_data');
load('Extracted_Variables.mat');
load('site_V.mat'); % <--- names of GPS stations for looping

% -- Point to function directory --  
addpath('/Volumes/volume/final_code_FINAL/Functions/');

% ======= INPUTS: Pick one of the follow from each =======

% -- Independent --
% Xvars = 'PkPrecipRt'; Xvar_name = 'Max rate of rain [mm/h]';
Xvars = 'PrecipDuration_hours'; Xvar_name = 'Duration of rain event [hours]';
% Xvars = 'Precip_volume'; Xvar_name = 'Volume of rain [mm]';
% Xvars = 'MaxTemp'; Xvar_name = 'Max temperature [c]';
% Xvars = 'MaxMWE'; Xvar_name = 'Max MWE [mm/h]';
% Xvars = 'TimeBtwnPeaks_days'; Xvar_name = 'Time between speed-ups [hours]';
% Xvars = 'pre_V_trend'; Xvar_name = 'Prior speed trend [m/d^2]';

% -- Dependent --
% Yvars = 'SpeedPeakY'; Yvar_name = 'Max speed [m/d]';
% Yvars = 'V_duration'; Yvar_name = 'Duration of speed-up event [hours]';
% Yvars = 'lag_time_precip_Rt'; Yvar_name = 'Lag between rain rate and speed [hours]';
Yvars = 'precent_inc_vel'; Yvar_name = 'Percent increase in speed';
% Yvars = 'lag_hours_from_Xcross'; Yvar_name = 'lag between MWE and speed [hours]';

% -- Line to fit ?? --
%line_type = 1; % <-- Linear
line_type = 2; % <-- Exponential 

% -- IF exponential, how many terms ? -- 
num_term = 'exp1';
%num_term = 'exp2';
% num_term = 'exp3';

% ========================================================

% -- Collect all data for X and Y var from each GPS station for each speed-up -- 
[X, Y] = gather_data(Extracted_Variables, site_V, Xvars, Yvars);

% -- Check both X&Y for NaNs -- 
idx = isnan(Y);
Y(idx) = [];
X(idx) = [];
idx = isnan(X);
Y(idx) = [];
X(idx) = [];

% -- Fit line to data --
if line_type == 1
    p = polyfit(X, Y, 1);
    y_fit = polyval(p, X);
    R = corr(X, Y);
else
    [f,gof] = fit(X,Y,num_term);
    R = gof.rsquare;
end

% -- Plot data -- 
figure('Position', [100, 100, 800, 1500]);
for i = 1:length(site_V)
    % current GPS station
    siteName_V = site_V{i};
    working_peaks = Extracted_Variables.(siteName_V);
    % year of current station for plot color
    yearcode_str = extractAfter(siteName_V,'_');
    yearcode = str2double(yearcode_str(1:2));
    % size of plot dots 
    sz = 250;
    if yearcode == 20 
        scatter(working_peaks.(Xvars)(:),working_peaks.(Yvars)(:),sz,[0.00 0.45 0.70],'filled','diamond')
        hold on
    end
    if yearcode == 21
        if strcmp(siteName_V, 'G15_2106') % 2021 surge data
            scatter(working_peaks.(Xvars)(:),working_peaks.(Yvars)(:),sz,[0.85 0.33 0.10],'filled','diamond')
            hold on
        else % 2021 quiescent data 
            scatter(working_peaks.(Xvars)(:),working_peaks.(Yvars)(:),sz,[0.85 0.33 0.10],'filled')
            hold on
        end
    end
    if yearcode == 22 
        scatter(working_peaks.(Xvars)(:),working_peaks.(Yvars)(:),sz,[0.93 0.69 0.13],'filled')
        hold on
    end
    if yearcode == 23 
        scatter(working_peaks.(Xvars)(:),working_peaks.(Yvars)(:),sz,[ 0.80 0.47 0.65],'filled')
        hold on
    end
    if yearcode == 24 
        scatter(working_peaks.(Xvars)(:),working_peaks.(Yvars)(:),sz,[0.00 0.60 0.50],'filled')
        hold on
    end
end 

% -- Add fitted line to plot: linear = red & expo = blue
hold on 
if line_type == 1
    plot(X, y_fit, 'r-', 'LineWidth', 1)
else
    plot(f,'-b')
end

% -- Title to show strength of relationship --
title(sprintf('Corro (R = %.2f)',R))

% -- Plot visuals 
ax = gca; 
ax.FontSize = 18;
grid on
xlabel(Xvar_name,'FontSize',16)
ylabel(Yvar_name,'FontSize',16)

% -- Legend -- 
h20 = scatter(nan,nan,sz,[0.00 0.45 0.70],'filled','diamond');   % Surge 20
h21S = scatter(nan,nan,sz,[0.85 0.33 0.10],'filled','diamond'); % Surge 21 (G15_2106)
h21Q = scatter(nan,nan,sz,[0.85 0.33 0.10],'filled');           % Quiescent 21
h22 = scatter(nan,nan,sz,[0.93 0.69 0.13],'filled');            % Quiescent 22
h23 = scatter(nan,nan,sz,[0.80 0.47 0.65],'filled');            % Quiescent 23
h24 = scatter(nan,nan,sz,[0.00 0.60 0.50],'filled');            % Quiescent 24
legend([h20 h21S h21Q h22 h23 h24], ...
    {'Surge 20','Surge 21','Quiescent 21','Quiescent 22','Quiescent 23','Quiescent 24'}, ...
    'Location','best');

% ==== What are the relationships if split by surge phase ====

% - Names of just surge and quiescent records 
surge_names = site_V(6:8);
quiescent_names = site_V;
quiescent_names(6:8) = [];

% -- Collect all data for X and Y var from each GPS station for each speed-up -- 
[s_X, s_Y] = gather_data(Extracted_Variables, surge_names, Xvars, Yvars);
[q_X, q_Y] = gather_data(Extracted_Variables, quiescent_names, Xvars, Yvars);

% -- Clear NaNs -- 
% surge
idx = isnan(s_Y);
s_Y(idx) = [];
s_X(idx) = [];
idx = isnan(s_X);
s_Y(idx) = [];
s_X(idx) = [];
% quiescent 
idx = isnan(q_Y);
q_Y(idx) = [];
q_X(idx) = [];
idx = isnan(q_X);
q_Y(idx) = [];
q_X(idx) = [];

% -- Fit line to data --
% surge
if line_type == 1
    s_R = corr(s_X, s_Y);
else
    [s_f,s_gof] = fit(s_X,s_Y,num_term);
    s_R = s_gof.rsquare;
end
surge_split_correlation = s_R
% quiescent 
if line_type == 1
    q_R = corr(q_X, q_Y);
else
    [q_f,q_gof] = fit(q_X,q_Y,num_term);
    q_R = q_gof.rsquare;
end
quiescent_split_correlation = q_R

