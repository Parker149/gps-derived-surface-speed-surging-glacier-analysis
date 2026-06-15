clear all; close all; clc; 

% -- Point script to directory where rain event data is stored --
addpath('/Users/wilke/OneDrive/Desktop/temp_data_store/');
load('data_RainEvents.mat');
names4loop = fieldnames(data_RainEvents);

% -- Load Rain Data --
addpath('/Users/wilke/OneDrive/Desktop/matlab_scripts/Functions/');
dataDir = '/Users/wilke/OneDrive/Desktop/temp_data_store/precip/';
site_P = loadRain(dataDir);
rain_names = fieldnames(site_P);

% - Input the same averaging block, in hrs, inputted in the "speed_profile_extract" script -
AVE_BLOCK = 4; % <---------- !!!!!!
numCols = 144/AVE_BLOCK + 1;

% -- Convert rain data to mm/h --
for i = 1:length(rain_names)
    site_P.(rain_names{i}).runoff = ((site_P.(rain_names{i}).runoff)/3) * 1000; 
end

% -- Ice11-22 has a rain event that falls right on the end of the analysis
% period, Nov 15. Due to this the corresponding speed profile (1:37) has 36
% NaNs, for the purposes of this code it is easiest to just remove this. 
data_RainEvents.precip11_2208(14,:) = [];

% -- Loop through each rain event and track accumulation along speed profiles -- 
for j = 1:length(names4loop)
    current_data = data_RainEvents.(names4loop{j});
    current_rain = site_P.(rain_names{j});
    if any(current_data.PrecipPeakY) % some records had no large rain events 
        rain_starts = current_data.PrecipStart; % start the track at the start of each rain event
        % create a matrix of NaNs that has #of rows for rain events and columns based on time blocks 
        data_store = nan(length(rain_starts), (144/AVE_BLOCK)+1);
        for a = 1:length(rain_starts)
            current_rain_start = rain_starts(a); % current rain event start 
            dataCols = table2array(current_data((a), 5:(5+numCols-1))); % current speed profile
            % we only want to track accumulation where there is speed data.
            % the speed profiles are all 6 days long but some rain events
            % are less than 6 days apart, getting the number of NaNs helps
            % us see how long to track rain accum
            numNans = sum(isnan(dataCols), 'all');
            if numNans == 0
                % no NaNs = the speed profile takes up the enitre 6 day window 
                date1 = current_rain_start - hours(AVE_BLOCK); % we have a time block before rain start
                date2 = current_rain_start + hours((144/AVE_BLOCK)-1)*AVE_BLOCK;
            else
                % if NaNs then the speed profile is just the number of time blocks with data 
                date1 = current_rain_start - hours(AVE_BLOCK);
                date2 = current_rain_start + hours((((144/AVE_BLOCK)-1)-numNans)*AVE_BLOCK);
            end
            % gather the rain rate data with in the defined range
            idx = find(current_rain.time >= date1 & current_rain.time <= date2);
            rain4acum = current_rain.runoff(idx);
            % convert to accum values
            rain4acum = rain4acum*3; 
            % Cummulative 
            accum_time_series = cumsum(rain4acum);
            % although the speed profiles and accumulation series cover the
            % same date range the data points are not aligned, for example
            % currently the accumualtion series is sampled every 3/hrs
            % while the speed data is every 4/hrs. we need to do some
            % interpolation to make sure they algin
            if numNans == 0 % the interpolation is based on the number of NaNs of the correspoding speed profile
                x1 = 1:length(accum_time_series);
                x2 = 1:(144/AVE_BLOCK)+1;
                alinged_accum = interp1(x1,accum_time_series,x2,'linear');
            else
                x1 = 1:length(accum_time_series);
                x2 = 1:((144/AVE_BLOCK)+1)-numNans;
                alinged_accum = interp1(x1,accum_time_series,x2,'linear');
            end
            % replace all the NaNs with the accum profile
            data_store(a,1:length(alinged_accum)) = alinged_accum;
        end
        accum_data.(names4loop{j}) = data_store;
    end
end

% - Surge names - 
s_name = names4loop;
s_name(1:5) = [];
s_name(4:5) = [];

% - Quiescene names - 
q_name = names4loop;
q_name(6:8) = [];

% - Data Store -
S_allData = [];
S_allClass = [];
Q_allData = [];
Q_allClass = [];

% gather all surge accum profiles and high or low sensitivity classifications
for j = 1:length(s_name)
    data4class = data_RainEvents.(s_name{j});
    if any(data4class.PrecipPeakY)
        data4profiles = accum_data.(s_name{j});
        classCol = data4class.class;
        S_allData = [S_allData; data4profiles];
        S_allClass = [S_allClass; classCol];
    end
end

% - surge high and low data - 
for j = 1:size(S_allData, 2)
    surge_high(:,j) = S_allData(S_allClass == 1, j);  
    surge_low(:,j) = S_allData(S_allClass == 0, j);
end

% gather all quiescent accum profiles and high or low sensitivity classifications
for j = 1:length(q_name)
    data4class = data_RainEvents.(q_name{j});
    if any(data4class.PrecipPeakY)
        data4profiles = accum_data.(q_name{j});
        classCol = data4class.class;
        Q_allData = [Q_allData; data4profiles];
        Q_allClass = [Q_allClass; classCol];
    end
end

% - quiescent high and low data - 
for j = 1:size(Q_allData, 2)
    quiescent_high(:,j) = Q_allData(Q_allClass == 1, j);  
    quiescent_low(:,j) = Q_allData(Q_allClass == 0, j);
end
    

% - create box plots -

% names for plotting 
x_edges = 0:(144/AVE_BLOCK+1);
boxNames = -AVE_BLOCK:AVE_BLOCK:length(x_edges)*AVE_BLOCK;
boxNames1 = num2cell(boxNames);

% === Quiescent === 
figure(1)

pos_q = [9.5, 0, 8, 150]; 
rectangle('Position', pos_q, ...
    'FaceColor', [0.7 0.7 0.7],'EdgeColor', [0.7 0.7 0.7],'FaceAlpha', 0.5); 
hold on
% 1. Plot the first set (High)
boxplot(quiescent_high, 'Positions', (1:(144/AVE_BLOCK)+1)-0.15, 'Widths', 0.2)

% 2. Find and color only the current boxes RED
h = findobj(gca, 'Tag', 'Box'); 
for j = 1:length(h)
    patch(get(h(j), 'XData'), get(h(j), 'YData'), [1 0 0], 'FaceAlpha', 0.5);
end

hold on

% 3. Plot the second set (Low)
boxplot(quiescent_low, 'Positions', (1:(144/AVE_BLOCK)+1)+0.15, 'Widths', 0.2)

% 4. Find ALL boxes, but use 'setdiff' to isolate the new ones
all_h = findobj(gca, 'Tag', 'Box');
hh = setdiff(all_h, h, 'stable'); % 'hh' now strictly contains only the second set's boxes

% 5. Color only the new boxes BLUE
for j = 1:length(hh)
    patch(get(hh(j), 'XData'), get(hh(j), 'YData'), [0 0 1], 'FaceAlpha', 0.5);
end
grid on
xticklabels(boxNames)
xlabel('Hours From Rain Event Start')
ylabel('Cumulative Rain [mm]')
title('Quiescent')
xlim([1.5 22.5])
ylim([0 150])


% === Surge === 
figure(2)

pos_s = [5.5, 0, 14, 150]; 
rectangle('Position', pos_s, ...
    'FaceColor', [0.7 0.7 0.7],'EdgeColor', [0.7 0.7 0.7],'FaceAlpha', 0.5); 
hold on

% 1. Plot the first set (High)
boxplot(surge_high, 'Positions', (1:(144/AVE_BLOCK)+1)-0.15, 'Widths', 0.2)

% 2. Find and color only the current boxes RED
h = findobj(gca, 'Tag', 'Box'); 
for j = 1:length(h)
    patch(get(h(j), 'XData'), get(h(j), 'YData'), [1 0 0], 'FaceAlpha', 0.5);
end

hold on

% 3. Plot the second set (Low)
boxplot(surge_low, 'Positions', (1:(144/AVE_BLOCK)+1)+0.15, 'Widths', 0.2)

% 4. Find ALL boxes, but use 'setdiff' to isolate the new ones
all_h = findobj(gca, 'Tag', 'Box');
hh = setdiff(all_h, h, 'stable'); % 'hh' now strictly contains only the second set's boxes

% 5. Color only the new boxes BLUE
for j = 1:length(hh)
    patch(get(hh(j), 'XData'), get(hh(j), 'YData'), [0 0 1], 'FaceAlpha', 0.5);
end
grid on
xticklabels(boxNames)
xlabel('Hours From Rain Event Start')
ylabel('Accumulation of Rain [mm]')
title('Surge')
xlim([1.5 22.5])
ylim([0 150])





