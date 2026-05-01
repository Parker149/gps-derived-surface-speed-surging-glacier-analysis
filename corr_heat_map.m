%% --- Correlation Heat Map Of Independent And Dependent Variables ---
clearvars; close all; clc;

% -- Load data --
addpath('/Users/parkerwilkerson/Desktop/test_data/GPS/analyzed_data/');
load('Extracted_Variables.mat');
site_V = fieldnames(Extracted_Variables);

% -- Variables used analyzed in thesis -- 
Xvars = {'PkPrecipRt','PrecipDuration_hours','Precip_volume','MaxTemp','MaxMWE','TimeBtwnPeaks_days','pre_V_trend'};
Yvars = {'SpeedPeakY','V_duration','lag_time_precip_Rt','precent_inc_vel','lag_hours_from_Xcross'};

% -- Create matrix to store correlation values -- 
R = nan(length(Yvars), length(Xvars));

% -- Loop to extract linear correlation coefficients for each variables pair --
for i = 1:length(Yvars)
    for j = 1:length(Xvars)
        allX = [];
        allY = [];
        for s = 1:length(site_V)
            T = Extracted_Variables.(site_V{s});   
            x = T.(Xvars{j});
            y = T.(Yvars{i});
            if strcmp(Yvars{i}, 'lag_time_precip_Rt')
                y = hours(y);
            end
            allX = [allX; x];
            allY = [allY; y];
        end
        valid = ~isnan(allX) & ~isnan(allY);
        allX = allX(valid);
        allY = allY(valid);
        if numel(allX) > 2   % safety check
            R(i,j) = corr(allX, allY, 'Type','Pearson');
        else
            R(i,j) = NaN;
        end
    end
end

% -- Create names for plots X and Y axis -- 
propper_y_names = {'Max speed', 'Duration of speed-up event', 'Lag between rain rate and speed', 'Percent increase in speed', 'lag between MWE and speed'};
propper_x_names = {'Max rate of rain', 'Duration of rain event', 'Volume of rain', 'Max temperature', 'Max MWE', 'Time between speed-ups', 'Prior speed trend'};

% -- Round correlation values --
R_rounded = round(R, 3);

% -- Create correlation heat map -- 
h = heatmap(propper_x_names, propper_y_names, R_rounded);
h.ColorLimits = [-1 1];
cmap = [linspace(0,1,128)' linspace(0,1,128)' ones(128,1); ...
        ones(128,1) linspace(1,0,128)' linspace(1,0,128)'];

% -- Color bar -- 
h.Colormap = cmap;
