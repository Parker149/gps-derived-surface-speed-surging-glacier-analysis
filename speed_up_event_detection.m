%% --- Script Used To Identify Speed-Up Events Of GPS Record ---
clearvars; close all; clc;

% -- Point script to directory where Detrended Data is stored --
addpath('/Users/parkerwilkerson/Desktop/test_data/GPS/');
load('detrend_data');

% -- Point to directory where raw GPS speed data is stored --
dataDir = '/Volumes/volume/CLEAN_ORGANIZED/Data/The_GPS_Archive/SK/Unfiltered_Velocities/';

% -- Load all data and create name for looping -- 
site_V = load_data_and_create_name_RAW(dataDir);
files = dir(fullfile(dataDir,'*.csv'));
raw_speeds = struct();
for i = 1:numel(files)
    fname = files(i).name;
    fpath = fullfile(dataDir,fname);
    T = readtable(fpath);
    fieldName = matlab.lang.makeValidName(erase(fname,'.csv'));
    raw_speeds.(fieldName) = T;
end

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
    raw = raw_speeds.(siteName_V);
    % NOTES: the end of G11-2208 becomes highly variable due to snow cover so extra triming is required 
    if strcmp(siteName_V, 'G11_2208')
        idx_trim = find(working_V.x > datetime(2022,10,28,00,00,00));
        working_V.detrend_y(idx_trim) = NaN;
        working_V.x(idx_trim) = NaT;
        working_V.detrend_y(idx_trim) = NaN;
        working_V.y(idx_trim) = NaN;
    end 
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
    % NOTES: G15_2106 needed a unique threshold 
    if strcmp(siteName_V, 'G15_2106')
        detectMask = ratio > 2.25;
    else
        detectMask = ratio > STA_LTA_threshold;
    end
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
    % Manual filtering was required for our data
    if strcmp(siteName_V, 'G11_2208') % <---- One peak was missed [+]
        g11 = find(clean_date == datetime(2022,09,15,16,00,45));
        plus_x = clean_date(g11);
        plus_y = clean_y(g11);
        x_data_for_table(length(y_data)+1) = plus_x;
        y_data(length(y_data)+1) = plus_y;
        [x_data_for_table,sort_idx] = sort(x_data_for_table);
        y_data = y_data(sort_idx);
    end
    if strcmp(siteName_V, 'G12_2008') % <---- One false positive [-]
        False_PosX = x_data_for_table(2);
        False_PosY = y_data(2);
        x_data_for_table(2) = [];
        y_data(2) = [];
    end
    if strcmp(siteName_V, 'G14_2008') % <---- Three false positives [-]
        False_PosX = x_data_for_table(5:7);
        False_PosY = y_data(5:7);
        x_data_for_table(5:7) = [];
        y_data(5:7) = [];
    end
    if strcmp(siteName_V, 'G15_2308') % <---- slight shift
        g14 = find(clean_date == datetime(2023,09,27,01,47,00));
        x_data_for_table(4) = clean_date(g14);
        y_data(4) = clean_y(g14);
    end
    % Store data 
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
    plot(T.SpeedPeakX,T.SpeedPeakY,'ko','MarkerFaceColor','g','MarkerSize',10)
    hold on
    if strcmp(siteName_V, 'G11_2208') % <---- [+]
        plot(plus_x,plus_y,'ko','MarkerFaceColor','b','MarkerSize',10)
    end
    if strcmp(siteName_V, 'G12_2008') % <---- [-]
        plot(False_PosX,False_PosY,'ko','MarkerFaceColor','r','MarkerSize',10)
    end
    if strcmp(siteName_V, 'G14_2008') % <---- [-(3x)]
        plot(False_PosX,False_PosY,'ko','MarkerFaceColor','r','MarkerSize',10)
    end
    grid on 
    ylabel('Speed [m/d]')
    title('Identified Peaks')
    yline(min_peak_thresh,'--','LineWidth',2,'Label','Min Speed Threshold')
    % plot for thesis 
    figure(11)
    if strcmp(siteName_V,'G14_2008')
        subplot(2,1,1)
    end
    if strcmp(siteName_V, 'G11_2208')
        subplot(2,1,2)
    end
    if strcmp(siteName_V,'G14_2008')||strcmp(siteName_V,'G11_2208')
        plot(raw.DecDates+0.00136612,raw.V_Total,'Color','k','LineWidth',0.75)
        hold on
        if strcmp(siteName_V, 'G11_2208')
            plot(clean_x, clean_y,'.','Color',[0.8353 0.6235 0.2196]); hold on; 
        else
            plot(clean_x, clean_y,'.','Color',[0.2863 0.5412 0.2627]); hold on; 
        end
        grid on
        xlabel('Decimal Year','FontSize',16)
        ylabel('Speeds [m/d]','FontSize',16)
        xlim([clean_x(1) clean_x(end)])
        ax = gca;
        ax.FontSize = 18;
        hold on 
        yline(min_peak_thresh,'--k')
        if strcmp(siteName_V,'G14_2008')
            plot(decyear(x_data_for_table), y_data, 'ko','MarkerFaceColor','g','MarkerSize',10); 
            plot(decyear(False_PosX), False_PosY, 'ko','MarkerFaceColor','r','MarkerSize',10); 
        end
        if strcmp(siteName_V, 'G11_2208')
            plot(decyear(x_data_for_table), y_data, 'ko','MarkerFaceColor','g','MarkerSize',10); 
            plot(decyear(x_data_for_table(3)), y_data(3), 'ko','MarkerFaceColor','b','MarkerSize',10);
        end
    end
end

%% --- Save Speed-Up Events as Matlab Struct ---

% -- All data is stored in -> data_peaks <- --

% -- Save data to desired directory --
saveDir = '/Users/parkerwilkerson/Desktop/test_data/GPS/'; % <------ input here [directory path]
save(fullfile(saveDir, 'data_peaks.mat'), 'data_peaks'); % <------ input here [file name]
