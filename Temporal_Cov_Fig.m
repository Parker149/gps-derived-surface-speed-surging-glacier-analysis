%% --- Temporal Coverage --- 
clear all; close all; clc;
addpath('/Users/parkerwilkerson/Desktop/test_data/GPS/station_temp_cov/');
% ==== FOR SIT KUSA ====
opts = detectImportOptions('SK_grouped_times.csv');
dateCols = {'DataRecordStart1','DataRecordEnd1','DataRecordStart2','DataRecordEnd2','DataRecordStart3','DataRecordEnd3','DataRecordStart4','DataRecordEnd4'};
for c = 1:length(dateCols)
    opts = setvartype(opts, dateCols{c}, 'char');
end
GPS = readtable('SK_grouped_times_CUT.csv', opts);
for c = 1:length(dateCols)
    GPS.(dateCols{c}) = strtrim(strrep(GPS.(dateCols{c}), '"',''));
end
allFormats = {'dd-MMM-yyyy HH:mm:ss', 'dd-MMM-yyyy H:mm:ss','yyyy-MM-dd HH:mm:ss', 'yyyy-MM-dd H:mm:ss'};
for c = 1:length(dateCols)
    col = GPS.(dateCols{c});
    dt = NaT(size(col));
    for f = 1:length(allFormats)
        bad = isnat(dt);
        if any(bad)
            try
                dt(bad) = datetime(col(bad), 'InputFormat', allFormats{f});
            catch
            end
        end
    end
    GPS.(dateCols{c}) = dt;
end
% ==== FOR SIT KUSA ====
surge = [datetime(2020,2,1) datetime(2021,9,1)];
surge = decyear(surge);
winter1 = [datetime(2020,10,1) datetime(2021,5,1)];
winter1 = decyear(winter1);
winter2 = [datetime(2021,10,1) datetime(2022,5,1)];
winter2 = decyear(winter2);
winter3 = [datetime(2022,10,1) datetime(2023,5,1)];
winter3 = decyear(winter3);
winter4 = [datetime(2023,10,1) datetime(2024,5,1)];
winter4 = decyear(winter4);
winter5 = [datetime(2024,10,1) datetime(2025,5,1)];
winter5 = decyear(winter5);
% ==== FOR YAHTSE ====
% GPS = readtable('GPS_Time_Record_Yahtse.csv');
% surge = [NaN NaN];
% surge = decyear(surge);
% winter1 = [datetime(2009,10,1) datetime(2010,5,1)];
% winter1 = decyear(winter1);
% winter2 = [datetime(2010,10,1) datetime(2011,5,1)];
% winter2 = decyear(winter2);
% winter3 = [NaN NaN];
% winter4 = [NaN NaN];
% ==== FOR Naluday ====
% GPS = readtable('GPS_Time_Record_Naluday.csv');
% surge = [datetime(2021,11,1) datetime(2022,10,20)];
% surge = decyear(surge);
% winter1 = [datetime(2021,10,1) datetime(2022,5,1)];
% winter1 = decyear(winter1);
% winter2 = [NaN NaN];
% winter3 = [NaN NaN];
% winter4 = [NaN NaN];
names = GPS.StationName;
numStations = height(GPS);
time = NaN(numStations, 8); 
for k = 1:4
    startCol = GPS.(sprintf('DataRecordStart%d',k));
    endCol   = GPS.(sprintf('DataRecordEnd%d',k));
    time(:,2*k-1) = decyear(startCol);
    time(:,2*k)   = decyear(endCol);
end
figure; hold on;
colors = lines(numStations);
for i = 1:numStations
    for k = 1:4
        startTime = time(i,2*k-1);
        endTime   = time(i,2*k);
        if ~isnan(startTime) && ~isnan(endTime)
            plot([startTime endTime], [i i], 'LineWidth', 10, 'Color', colors(i,:))
        end
    end
end
ylim([0 numStations+1]);
set(gca,'YTick',1:numStations,'YTickLabel',names)
xlabel('Decimal Year','FontSize',14)
ylabel('Station','FontSize',14)
title('Data Coverage of Stations')
grid on
ax = gca; ax.FontSize = 16;
limity = ylim;
xLimits = xlim;
rectangle('Position',[surge(1),limity(1),surge(2)-surge(1),limity(2)],'FaceColor','r','FaceAlpha',.1);
winterCells = [winter1; winter2; winter3; winter4; winter5];
for w = 1:size(winterCells,1)
    rectangle('Position',[winterCells(w,1), limity(1), winterCells(w,2)-winterCells(w,1), limity(2)],'FaceColor','b','FaceAlpha',.1);
end
xlim(xLimits)