%% --- Script Used To Extract Speed Profiles Around Rain Events ---
clearvars; close all; clc;

% -- Point script to directory where Detrended Data is stored --
addpath('/Volumes/volume/Data/The_GPS_Archive/SK/Detrended/');
load('detrend_data');
V_names = fieldnames(detrend_data);

% -- Point script to directory where data_peaks.mat is stored --
addpath('/Volumes/volume/Data/The_GPS_Archive/SK/analyzed_data/');
load('data_peaks');
SpeedUpDates = data_peaks;
clear data_peaks

% -- Point script to directory where functions are stored --
addpath('/Volumes/volume/matlab_scripts/Functions/');

% -- Load Rain Data --
dataDir = '/Volumes/volume/Data/weather/SK/model_data_used_for_thesis/precip/';
site_P = loadRain(dataDir);
R_names = fieldnames(site_P);

%% --- Inputs To Be Tuned --- 

% -- Min dist between two rain event peaks -- 
min_peak_dist = 8 ; % <-- sample rate @ 3 hrs, 8 = 1 day 

% -- Min peak height of a rain event --
peak_input = 0.006;
min_peak_height = (peak_input/3)*1000; % <-- convert from m/hr^3 to mm/hr

% -- Date range for analysis -- 
start_month = 6;   
start_day   = 1;
end_month   = 11; 
end_day     = 15; 

% -- min value considered to be the start and end of a rain event -- 
rain_thresh_input = 0.002;
rain_thresh = (rain_thresh_input/3)*1000; % <-- convert from m/hr^3 to mm/hr

% -- size of averaging blocks for speed profiles -- 
AVE_BLOCK = 4; % <-- in hours 
%% --- Identify All Large Rain Events ---

data_RainEvents = struct();

for q = 1:length(R_names)
    % - names for looping 
    siteName_V = V_names{q};
    siteName_P = R_names{q};
    % - current data sets 
    working_V = detrend_data.(siteName_V);
    working_precip = site_P.(siteName_P);
    % - proper units and date trimming 
    rain_y = ((working_precip.runoff)/3)*1000;
    rain_x = working_precip.time; 
    keep_rows = (rain_x.Month > start_month | ...
                 (rain_x.Month == start_month & rain_x.Day >= start_day)) & ...
                (rain_x.Month < end_month | ...
                 (rain_x.Month == end_month & rain_x.Day <= end_day));
    rain_x(~keep_rows)   = NaT;
    rain_y(~keep_rows) = NaN;
    % - G11_2208 needs to be trimmed ever so slightly (strange rain event at the start)
    if strcmp(siteName_P, 'precip11_2208')
       rain_x =  rain_x(5:end);
       rain_y =  rain_y(5:end);
    end
    % - identify peaks and extract data for x and y 
    [maxs locs] = findpeaks(rain_y,'MinPeakDistance',min_peak_dist,'MinPeakHeight',min_peak_height);
    x = rain_x(locs);
    y = rain_y(locs);
    % - find peaks in velocity (only used to identify compound rain events 
    vel_X = working_V.x;
    vel_Y = working_V.detrend_y;
    [v_max v_locs] = findpeaks(vel_Y);
    peak_v_x = vel_X(v_locs);
    if strcmp(siteName_P, 'precip14_2008')
        % NOTES: I believe that one peak of Ice14 has a peak that is too
        % smooth to be identified by findpeaks? However this is clearly a
        % peak, that happens to be identified by our STA/LTA method. To
        % deal with this we will just foce this peak, via date, to be
        % identified. 
        count = length(peak_v_x)+1;
        peak_v_x(count) = datetime(2020,09,29,15,40,00);
        peak_v_x = sort(peak_v_x);
    end
    peak_v_y = vel_Y(v_locs);
    % - identify compound rain events
    % EVENT TYPE KEY
    % 1 = Normal
    % 2 = Compound
    % set all to 1 to start
    keep = true(size(x));  
    event_type = ones(size(x));
    % How this works: If no velocity peak is found between the current rain
    % event and the next, then that means the velocity profile between
    % these two events is continouosly increase (how we define a compound
    % rain event) 
    for i = 1:length(x)-1 % don't care about final rain event
        current = x(i); % date of current rain event peak
        next_current = x(1+i); % date of the next rain event peak
        between_id = find(peak_v_x >= current & peak_v_x <= next_current); % are there any velocity peaks between current rain and next  
        if isempty(between_id) % no peaks found, event type = 2 
            keep(i+1) = false;    
            %event_type(i+1) = 2;
            event_type(i) = 2;
        end
    end
    % - we remove the next rain event if: event_type = 2 
    x = x(keep);
    y = y(keep);
    event_type = event_type(keep);
    % - date of start of rain event 
    precip_start = NaT(size(x));
    for j = 1:length(x)
        if j == 1
            % for the first rain event, all rain dates before the current loop's peak 
            left_idx = find(rain_x >= rain_x(1) & rain_x <= x(j));
        else
            % for any but the first, dates are from last peak to current peak 
            left_idx = find(rain_x >= x(j-1) & rain_x <= x(j));
        end
        left_rain = rain_y(left_idx); % rain data defined from above 
        edge_left_idx = find(left_rain <= rain_thresh, 1, 'last'); % start on the right side of the profile and find the first value to meet threshold
        if isempty(edge_left_idx)
            [~, edge_left_idx] = min(left_rain); % if nothing meets thresh, find the min 
        end
        t_left = rain_x(left_idx(edge_left_idx));
        precip_start(j) = t_left(:);
    end
    % - complie data
    T = table(x(:), y(:), precip_start(:), event_type(:), 'VariableNames', {'PrecipPeakX', 'PrecipPeakY','PrecipStart','event_type'});
    data_RainEvents.(siteName_P) = T;
    % - plot data 
    if length(y) >= 1
        figure(q)
        plot(rain_x,rain_y,'-b')
        hold on
        plot(x,y,'ko')
        xline(precip_start)
        ylabel('Rain Rate [mm/h]')
        grid on
        yline(min_peak_height,'--b','Label','Rain Event Min Peak Height')
        yline(rain_thresh,'--m','Label','Rain Event Start')
        title(siteName_V)
    end
end

%% --- Extract Speed Profiles For Each Rain Event 

for ii = 1:length(R_names)
   % - names for looping 
    siteName_V = V_names{ii};
    siteName_P = R_names{ii};
    % - detrend data  
    working_V = detrend_data.(siteName_V);
    vel_X = working_V.x;
    vel_Y = working_V.detrend_y;
    vel_raw = working_V.y;
    vel_spline = working_V.data_spline;
    % - rain events 
    current_rain_data = data_RainEvents.(siteName_P);
    X4peaks = current_rain_data.PrecipPeakX;
    X4starts = current_rain_data.PrecipStart;
    numPeaks = length(X4peaks);
    % - speed up events 
    current_speed_up = SpeedUpDates.(siteName_V);
    % - loop through rain events of current data set 
    for jj = 1:numPeaks
        % - current rain event 
        current_event_peak = X4peaks(jj);
        current_event_start = X4starts(jj);
        % - from the start of our current rain event to + 6 days, break
        % this into evenly space time blocks in hours defined by AVE_BLOCK
        start_times = current_event_start + hours(-AVE_BLOCK) + hours(AVE_BLOCK)*(0:(144/AVE_BLOCK));
        % - time between rain events
        if jj < numPeaks
            % length = from current rain peak to next rain peak 
            next_peak = X4peaks(jj+1);
            time_diff = next_peak - current_event_peak;
        else
            % if on last rain event, length = current event + 6 days 
            next_peak = [];
            time_diff = days(6);
        end
        % - extract profiles and average 
        if time_diff >= days(6)
            for cyc = 1:(144/AVE_BLOCK)+1
                % - current time block to average speed data 
                working_window = [start_times(cyc), start_times(cyc)+hours(AVE_BLOCK)];
                % - what speed data is in this time block 
                idx = vel_X >= working_window(1) & vel_X <= working_window(2);
                % - average that speed data and store it 
                Vdata4AVG(cyc) = nanmean(vel_Y(idx));
            end
        else
            Vdata4AVG(1:(144/AVE_BLOCK)+1) = NaN; % set the speed profile to all NaNs
            % speed data between current rain start to next rain peak 
            idx1 = vel_X >= current_event_start & vel_X <= next_peak;
            working_veloicty_times = vel_X(idx1);
            % since we preallocate the speed profile as NaNs we need to
            % ~manually input, before looping, the first two time blocks of
            % the speed profile. With the way the below 'k' loop is set up,
            % if we don't do this, the first two speed blocks of this
            % condition's profile will be NaNs 
            idx2 = vel_X >= current_event_start - hours(AVE_BLOCK) & vel_X <= current_event_start;
            Vdata4AVG(1) = nanmean(vel_Y(idx2));
            idx_block2 = vel_X >= current_event_start & vel_X <= current_event_start + hours(AVE_BLOCK);
            Vdata4AVG(2) = nanmean(vel_Y(idx_block2));   
            % what start_times, averaging blocks, are within the above window? 
            idx3 = find(start_times >= working_veloicty_times(1) & start_times <= working_veloicty_times(end));
            % loop through each start_time found above and average the speed within that range 
            for k = 1:length(idx3)
                spot = idx3(k); 
                window_start = start_times(spot);
                idx4 = vel_X >= window_start & vel_X <= window_start + hours(AVE_BLOCK);
                Vdata4AVG(spot) = nanmean(vel_Y(idx4));
            end
        end
        % - store speed profile data into rain event struct 
        for b = 1:(144/AVE_BLOCK)+1
            data_RainEvents.(siteName_P).(sprintf('b%d',b))(jj) = Vdata4AVG(b);
        end
        % - Is this current rain event a high or low sensitivty event? 
        cols = 1:(144/AVE_BLOCK)+1; % indicies of speed profile
        vals = Vdata4AVG(cols); % speed profile data 
        isNaN = isnan(vals); % where are there NaNs in the speed profile if any 
        firstNaN = find(isNaN,1,'first'); % find the first NaN in the speed profile
        % - each speed profile will be a certain length, that length is equal
        % to a certain number of hours. Here we create a search window,
        % defined by this number of hours to see if a speed up event is
        % within this window 
        if isempty(firstNaN)
            numValid = numel(cols);  
        else
            numValid = firstNaN - 1;
        end
        window = hours(numValid * AVE_BLOCK); 
        end_window = current_event_start + window;
        % - do any dates of a speed up event fall with in the current rain event's window? 
        inWindow = current_speed_up.SpeedPeakX > current_event_start & ...
                   current_speed_up.SpeedPeakX < end_window; 
        if any(inWindow)
            class = 1; % = HIGH SENSITIVY EVENT
        else
            class = 0; % = LOW SENSITIVTY EVENT
        end
        data_RainEvents.(siteName_P).class(jj) = class;
        % - Is the current data from the surge or quiescent phase ? 
        if ismember(siteName_V, {'G14_2008', 'G12_2008', 'G15_2106'})
            data_RainEvents.(siteName_P).surge(1:numPeaks) = 1; % = SURGE 
        else
            data_RainEvents.(siteName_P).surge(1:numPeaks) = 0; % = QUIESCENT 
        end
    end
end

% -- Sensitivity Frequencies -- 
% total 
total_prec = [];
for q = 1:length(R_names)
    siteName_P = R_names{q};
    working_data = data_RainEvents.(siteName_P);
    if any(working_data.event_type)
        total_prec = [total_prec; working_data.class];
    end
end
high_sens = find(total_prec == 1);
Total_Precent_High_Sensitivity = length(high_sens) / length(total_prec)
% surge
surge_prec = [];
surge_name = R_names;
surge_name(1:5) = [];
surge_name(4:5) = [];
for q = 1:length(surge_name)
    siteName_P = surge_name{q};
    working_data = data_RainEvents.(siteName_P);
    if any(working_data.event_type)
        surge_prec = [surge_prec; working_data.class];
    end
end
high_sens = find(surge_prec == 1);
Surge_Precent_High_Sensitivity = length(high_sens) / length(surge_prec)
% quiescent 
quiesc_prec = [];
q_name = R_names;
q_name(6:8) = [];
for q = 1:length(q_name)
    siteName_P = q_name{q};
    working_data = data_RainEvents.(siteName_P);
    if any(working_data.event_type)
        quiesc_prec = [quiesc_prec; working_data.class];
    end
end
high_sens = find(quiesc_prec == 1);
Quiescent_Precent_High_Sensitivity = length(high_sens) / length(quiesc_prec)
%% ==== Box Plot ==== 

x_edges = 0:(144/AVE_BLOCK+1);
boxNames = -AVE_BLOCK:AVE_BLOCK:length(x_edges)*AVE_BLOCK;
boxNames = num2cell(boxNames);
x_centers = 0.5:1:(144/AVE_BLOCK)+0.5;

% -- Surge Plot -- 
site_name = R_names;
site_name(1:5) = [];
site_name(4:5) = [];
figure(11)
figure('Position', [100, 100, 1800, 900]);
plot_speed_profiles_boxes(data_RainEvents, site_name, AVE_BLOCK);
xline(2, 'b', 'LineWidth', 2);
title('Surge Speed Profiles')
xticklabels(boxNames)
xlabel('Hours From Rain Event Start')

% -- Quiescent Plot -- 
site_name = R_names;
site_name(6:8) = [];
figure(12)
figure('Position', [100, 100, 1800, 900]);
plot_speed_profiles_boxes(data_RainEvents, site_name, AVE_BLOCK);
xline(2, 'b', 'LineWidth', 2);
title('Quiescent Speed Profiles')
xticklabels(boxNames)
xlabel('Hours From Rain Event Start')


%% --- Save Data as Matlab Struct ---

% -- Save data to desired directory --
saveDir = '/Volumes/volume/Data/The_GPS_Archive/SK/analyzed_data/'; % <------ input here [directory path]
save(fullfile(saveDir, 'data_RainEvents.mat'), 'data_RainEvents'); % <------ input here [file name]

            
       