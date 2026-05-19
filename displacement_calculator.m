%% --- Displacement Statistics ---
clear all; close all; clc; 

addpath('/Volumes/volume/Data/The_GPS_Archive/SK/analyzed_data/');
load('data_RainEvents.mat');
V_names = fieldnames(data_RainEvents);
load('GPS_Stats.mat');
names4stats = fieldnames(GPS_Statistics);

% - Input the same averaging block, in hrs, inputted in the "speed_profile_extract" script -
AVE_BLOCK = 4; % <---------- !!!!!!

% == How much additional displacment occurs during the SURGE from the high sensitivty events? ==

% - Surge names - 
site_name = V_names;
site_name(1:5) = [];
site_name(4:5) = [];

% - Data Store -
allData = [];
allClass = [];
numCols = 144/AVE_BLOCK + 1;

% - loop through speed profiles and grab all surge speed profiles and high or low sensitivty class type -
for i = 1:length(site_name)
    tbl = data_RainEvents.(site_name{i});
    if any(tbl.PrecipPeakY)
        dataCols = table2array(tbl(:, 5:(5+numCols-1)));
        classCol = tbl.class;
        allData = [allData; dataCols];
        allClass = [allClass; classCol];
    end
end

% - for high and low time blocks what is the average speed? - 
for j = 1:size(allData, 2)
    data0 = allData(allClass == 1, j);  
    data1 = allData(allClass == 0, j);
    surge_hs(j) = nanmean(data0);
    surge_ls(j) = nanmean(data1);
end

% - Input cutt off points (where the high and low profiles diverge and then re-connect) - 

cutt_off = [3 22]; % <-- Input as indicies 

% - Plot - 
subplot(2,1,1)
plot(surge_hs,'-or')
hold on
plot(surge_ls,'-ob')
ylabel('Speed [m/d]')
title('characteristic Surge High And Low Profiles')
grid on
xline(cutt_off,'k-','LineWidth',1.5)

% - Calc in meters the additional displacement that occurs from high sens events - 

% dist traveled (convert from m/d speeds over 4 hour blocks to meters)
surge_hs_dist_travel = (surge_hs(cutt_off(1):cutt_off(2))./24)*4;
surge_ls_dist_travel = (surge_ls(cutt_off(1):cutt_off(2))./24)*4;

% difference between dist traveled for every point along profile
diff_displace = surge_hs_dist_travel - surge_ls_dist_travel;

% cumulative difference 
surge_total_displace = sum(diff_displace)


% ----- REPEAT FOR QUIESCENCE ----- 
clear site_name allData allClass numCols data0 data1 cutt_off diff_displace
% == How much additional displacment occurs during the QUIESCENE from the high sensitivty events? ==

% - Quiescene names - 
site_name = V_names;
site_name(6:8) = [];

% - Preallocate storing - 
allData = [];
allClass = [];
numCols = 144/AVE_BLOCK + 1;

% - loop through speed profiles and grab all surge speed profiles and high or low sensitivty class type -
for i = 1:length(site_name)
    tbl = data_RainEvents.(site_name{i});
    if any(tbl.PrecipPeakY)
        dataCols = table2array(tbl(:, 5:(5+numCols-1)));
        classCol = tbl.class;
        allData = [allData; dataCols];
        allClass = [allClass; classCol];
    end
end

% - for high and low time blocks what is the average speed? - 
for j = 1:size(allData, 2)
    data0 = allData(allClass == 1, j);  
    data1 = allData(allClass == 0, j);
    quies_hs(j) = nanmean(data0);
    quies_ls(j) = nanmean(data1);
end

% - Input cutt off points (where the high and low profiles diverge and then re-connect) - 

cutt_off = [9 19]; % <-- Input as indicies 

% - Plot - 
subplot(2,1,2)
plot(quies_hs,'-or')
hold on
plot(quies_ls,'-ob')
ylabel('Speed [m/d]')
title('characteristic Surge High And Low Profiles')
grid on
xline(cutt_off,'k-','LineWidth',1.5)

% - Calc in meters the additional displacement that occurs from high sens events - 

% dist traveled (convert from m/d speeds over 4 hour blocks to meters)
quies_hs_dist_travel = (quies_hs(cutt_off(1):cutt_off(2))./24)*4;
quies_ls_dist_travel = (quies_ls(cutt_off(1):cutt_off(2))./24)*4;

% difference between dist traveled for every point along profile
diff_displace = quies_hs_dist_travel - quies_ls_dist_travel;

% cumulative difference 
quies_total_displace = sum(diff_displace)

% - prepare stats to store - 
clear tbl
for i = 1:length(names4stats)
    tbl = GPS_Statistics.(names4stats{i});
    displacement_stats.(names4stats{i}).length_of_recod = tbl.length_of_record;
    num_speedups = tbl.anomaly_count; 
    if ismember(names4stats{i}, {'G14_2008', 'G12_2008', 'G15_2106'})
        displacement_stats.(names4stats{i}).speedup_cum_dist = num_speedups * surge_total_displace;
    else
        displacement_stats.(names4stats{i}).speedup_cum_dist = num_speedups * quies_total_displace;
    end
end

%% --- How Far Did Each GPS Station Travel Over Our Peroid Of Examination ---

% - load in all positions -
addpath('/Volumes/volume/matlab_scripts/Functions/');
dataDir = '/Volumes/volume/Data/The_GPS_Archive/SK/all_positions/';
site_T = loadTemp(dataDir);

% - we need to remove the emlid stations - 
GPS_names = fieldnames(site_T);
GPS_names(1:5) = [];
for i = 1:length(GPS_names)
    station_travel.(GPS_names{i}) = site_T.(GPS_names{i});
end
clear site_T

% - calc dist travel for each - 
clc
for z = 1:length(GPS_names)
    tbl = station_travel.(GPS_names{z}); % current data set 
    % need data to determine dist travel 
    lat = tbl.latitude_decimal_degree;
    lon = tbl.longitude_decimal_degree;
    time = tbl.datetimes;
    % covert to utm and decyear for cleaning
    [x,y,zone] = ll2utm(lat,lon);
    time_dec = decyear(time);
    % remove redundant values   
    [C,IA] = unique(time_dec);
    clean_dec = time_dec(IA);
    clean_dat = time(IA);
    clean_x = x(IA);
    clean_y = y(IA);
    % only need positions from our study period Aug 1 to Nov 15
    % we can get this from length of record stats from earlier
    day_count = GPS_Statistics.(names4stats{z}).length_of_record;
    idx = find(clean_dat >= clean_dat(1) & clean_dat <= clean_dat(1)+days(day_count));
    clean_dec = clean_dec(idx);
    clean_dat = clean_dat(idx);
    clean_x = clean_x(idx);
    clean_y = clean_y(idx);
    % apply a moving window mean of 1 day to x and y positions 
    % 5760 is the number of indicies in a day based on our sample rate 
    smooth_x = movmean(clean_x,5760);
    smooth_y = movmean(clean_y,5760);
    % distance traveled based on those smoothed positions
    if strcmp(GPS_names{z}, 'all_positions_G11_2408')
        % the first couple thousand positions of G11_24 are from Yakutat
        distance = sqrt( (smooth_x(end)-smooth_x(3500))^2 + ...
                    (smooth_y(end)-smooth_y(3500))^2 );
    else
        distance = sqrt( (smooth_x(end)-smooth_x(1))^2 + ...
                    (smooth_y(end)-smooth_y(1))^2 );
    end
    % store above in displacment stats struct
    displacement_stats.(names4stats{z}).total_dist_travel = distance;
    % how much displacment is from the speed ups?
    speedup = displacement_stats.(names4stats{z}).speedup_cum_dist;
    speedup_prec = speedup/distance;
    % store in stats struct
    displacement_stats.(names4stats{z}).precent_displace_from_speedup = speedup_prec;
end


