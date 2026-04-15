%% --- Script Used To Identify Speed-Up Events Of GPS Record ---
clearvars; close all; clc;

% -- Point script to directory where Detrended Data is stored --
addpath('/Users/parkerwilkerson/Desktop/test_data/GPS/');
load('detrend_data');

% -- Extract names for looping --
names = fieldnames(detrend_data);

% -- Input thresholds --

% READ ME: play around with these inputs until peak detection is working as you like 

min_peak_thresh = 0.65; % <------ input here
% The peak speeds of a speed-up event has to be at minimum greater than this value 

STA_num_days = 0.75; % <------ input here
% This is the window size of the moving window applied in the short term average time serires 

LTA_num_days = 90; % <------ input here
% This is the window size of the moving window applied in the long term average time serires 

STA_LTA_threshold = 1.9; % <------ input here
% An identified peak has to have a ratio time series peak greater than this

min_num_days = 2; % <------ input here
% Speed-up events have to be at least X number of days apart

% -- Input thresholds --

% ==== Identify Veloicty Peaks ==== 
for q = 1:length(names)
    % grab GPS record
    siteName_V = names{q};
    working_V = detrend_data.(siteName_V);
    % remove NaNs
    valid_idx = ~isnan(working_V.detrend_y);
    clean_x = decyear(working_V.x(valid_idx));
    clean_y = working_V.detrend_y(valid_idx);
    clean_date = working_V.x(valid_idx);
    % define decimal day
    DecDay = 0.0027379;
    % compute sampling interval in years
    dt = median(diff(clean_x));  
    % STA/LTA window lengths 
    STA_time_days = DecDay * STA_num_days;   
    LTA_time_days = DecDay * LTA_num_days;   
    % convert to number of samples
    N_sta = max(1, round(STA_time_days / dt));
    N_lta = max(1, round(LTA_time_days / dt));
    % compute STA and LTA time series
    STA = movmean(abs(clean_y), N_sta);
    LTA = movmean(abs(clean_y), N_lta);
    % avoid divide-by-zero
    eps_val = 1e-12;
    ratio = STA ./ (LTA + eps_val);
    % detection               
    detectMask = ratio > STA_LTA_threshold;
    y_detect = clean_y .* detectMask;
    mindist = 5760 * min_num_days;
    [~, locs] = findpeaks(y_detect,'MinPeakDistance',mindist);
    % complie data 
    x_data = clean_x(locs);
    x_data_for_table = clean_date(locs);
    y_data = clean_y(locs);
    filt_idx = find(y_data <= min_peak_thresh);
    y_data(filt_idx) = [];
    x_data_for_table(filt_idx) = [];
    x_data(filt_idx) = [];
    T = table(x_data_for_table(:), y_data(:), 'VariableNames', {'SpeedPeakX', 'SpeedPeakY'});
    data_peaks.(siteName_V) = T;
    % plot
    figure(q)
    subplot(2,1,1)
    plot(clean_date,ratio,'-b')
    yline(STA_LTA_threshold,'k','LineWidth',2,'Label','Ratio Threshold')
    grid on
    title(siteName_V,'STA/LTA Time Series')
    ylabel('Unitless')
    subplot(2,1,2)
    plot(working_V.x,working_V.detrend_y,'-r')
    hold on
    plot(T.SpeedPeakX,T.SpeedPeakY,'ko','MarkerFaceColor','b','MarkerSize',10)
    grid on 
    ylabel('Speed [m/d]')
    title('Identified Peaks')
    yline(min_peak_thresh,'--','LineWidth',2,'Label','Min Speed Threshold')
end

%% --- Save Speed-Up Events as Matlab Struct ---

% -- All data is stored in -> data_peaks <- --

% -- Save data to desired directory --
saveDir = '/Users/parkerwilkerson/Desktop/test_data/GPS/'; % <------ input here [directory path]
save(fullfile(saveDir, 'data_peaks.mat'), 'data_peaks'); % <------ input here [file name]
