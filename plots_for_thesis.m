%% --- Figure: Speed Times-Series Of Surge Pair and Quiescent Pair --- 
clear all; close all; clc; 

% ==== Color codes for all GPS records ====
Ice11_color = [0.8353 0.6235 0.2196];
Ice15_color = [0.1569 0.6667 0.9451];
Ice12_color = [0.5020 0.0667 0.7569];
Ice14_color = [0.2863 0.5412 0.2627];
Ice09_color = [0.0588 0.4000 0.7765];
Rock10_color = [0.7882 0.2627 0.0941];

% -- Point to directory --
addpath('/Users/parkerwilkerson/Desktop/test_data/GPS/filtered/');

% -- Read in filtered speed data -- 
G12 = readtable('G12_2008_filt.csv');
G14 = readtable('G14_2008_filt.csv');
G15 = readtable('G15_2208_filt.csv');
G11 = readtable('G11_2208_filt.csv');

subplot(2,1,1)
plot(G12.clean_date,G12.filt_speed,'-','Color',Ice12_color,'LineWidth',1.75)
hold on
plot(G14.clean_date,G14.filt_speed,'-','Color',Ice14_color,'LineWidth',1.75)
grid on
xlim([datetime(2020,09,01,00,00,00) datetime(2020,10,18,00,00,00)])
ylabel('Speeds [m/d]','FontSize',16);
ax = gca;
ax.FontSize = 15;
legend('Ice12-2008','Ice14-2008')

subplot(2,1,2)
plot(G11.clean_date,G11.filt_speed,'-','Color',Ice11_color,'LineWidth',1.75)
hold on
plot(G15.clean_date,G15.filt_speed,'-','Color',Ice15_color,'LineWidth',1.75)
grid on
xlim([datetime(2022,09,01,00,00,00) datetime(2022,10,18,00,00,00)])
ylabel('Speeds [m/d]','FontSize',16);
ax = gca;
ax.FontSize = 15;
legend('Ice11-2208','Ice15-2208')

%% --- Figure: Detrend Example Of Ice12-2008 --- 
clear all; close all; clc;
addpath('/Users/parkerwilkerson/Desktop/test_data/GPS/');
load('detrend_data.mat')

subplot(1,2,1)
plot(detrend_data.G12_2008.x,detrend_data.G12_2008.y,'.','Color',[0.5020 0.0667 0.7569])
hold on
plot(detrend_data.G12_2008.x,detrend_data.G12_2008.data_spline,'k.')
grid on
ax = gca;
ax.FontSize = 15;
ylabel('Speeds [m/d]','FontSize',16)

subplot(1,2,2)
plot(detrend_data.G12_2008.x,detrend_data.G12_2008.detrend_y,'.','Color',[0.5020 0.0667 0.7569])
grid on
ax = gca;
ax.FontSize = 15;
ylabel('Speeds [m/d]','FontSize',16)

%% --- Yakutat Rain Data To EBFM Rain Data ---
clear all; close all; clc;

% -- Directories -- 
addpath('/Volumes/volume/CLEAN_ORGANIZED/Data/weather/SK/Non_Model_Climate_data/');
addpath('/Volumes/volume/CLEAN_ORGANIZED/Data/weather/SK/model_data_used_for_thesis/precip/');

% -- Model data -- 
model = readtable("precip11_2208.csv");

% -- Yakutat data -- 
Yak = readtable('YAK_airport_weather_1917-2025.csv');

% -- Average each day of model precip to be in scale with Yak data -- 
TT = timetable(model.time, model.runoff);
TT_daily = retime(TT, 'daily', 'sum');

% -- Add 12 hours to Yak time to center it -- 
Yak.Date = Yak.Date+ hours(12); 

% -- Date range for plot compare -- 
start = model.time(1);
endy = datetime(2022,11,16,0,0,0);


% -- Yakutat Airport area -- 
area(Yak.Date, (Yak.PRCP_Inches_*.0254)*1000, 'FaceColor', [1 0.5 0])
ylabel('Precipitation [mm/d]','FontSize',16);
hold on

% -- Model data with transparency -- 
h = area((TT_daily.Time + hours(12)), TT_daily.Var1*1000, 'FaceColor', [0.5 0.8 1.0]);
h.FaceAlpha = 0.75;  

% -- Final plotting adjustments -- 
xlim([start, endy])
grid on
ax = gca;
ax.FontSize = 18;
legend('Yakutat Airport','EBFM')
ylim([0 125])

%% --- Figure: Rock10 Easting Frequencies Pre And Post Filtering And Sample Corner Frequencies Of Rock10 --- 
clear; close all; clc;

% -- Rock10 data -- 
addpath('/Volumes/volume/CLEAN_ORGANIZED/Data/The_GPS_Archive/SK/Rock_data/GRock_2108/');
Rock_Raw = readtable('Grock_2108.csv');
Rock_Filt = readtable('Grock_2108_filt.csv');

% -- RMSE values for Rock10 @ different corner frequencies -- 
addpath('/Users/parkerwilkerson/Desktop/test_data/GPS/analyzed_data');
load('Rock_RMSE_CF.mat');

% -- Frequency domain of unfiltered Rock10 easting --
% variables
VX = Rock_Raw.X_Vel;
ts1 = datenum(Rock_Raw.Dates);
% clean data 
valid = isfinite(VX);
VX1 = VX(valid);
tsu1 = ts1(valid);
% sampling rate 
fs = 1/15;
fd = fs*86400;
% frequnecy domain 
NX = length(tsu1);        
YX = fft(VX1);           
P2X = abs(YX/NX);            
P1X = P2X(1:floor(NX/2)+1);   
P1X(2:end-1) = 2*P1X(2:end-1); 
fX = fd*(0:(NX/2))/NX;   

% -- Unfiltered Rock10 -- 
subplot(1,2,1)
plot(fX, P1X,'-r','LineWidth',2)
xlabel('Frequency (cycles per day)')
ylabel('Amplitude','FontSize',14);
title('Frequency Domain (EASTING)','FontSize',14);
xlim([0 7])
ylim([0 .22])
grid on
hold on
ax = gca;
ax.FontSize = 16;

% -- Frequency domain of filtered Rock10 easting --
% variables
VX = Rock_Filt.filtX;
time_shift = Rock_Filt.Dates - hours(12);
ts1 = datenum(time_shift);
% clean
valid = isfinite(VX);
VX1 = VX(valid);
tsu1 = ts1(valid);
% frequnecy domain 
NX = length(tsu1);        
YX = fft(VX1);           
P2X = abs(YX/NX);            
P1X = P2X(1:floor(NX/2)+1);   
P1X(2:end-1) = 2*P1X(2:end-1); 
fX = fd*(0:(NX/2))/NX; 

% -- Filtered Rock10 -- 
subplot(1,2,1)
plot(fX, P1X,'-b','LineWidth',2)
xlabel('Frequency (cycles per day)')
ylabel('Amplitude','FontSize',14);
title('Frequency Domain (EASTING)','FontSize',14);
xlim([0 7])
ylim([0 .2])
corner = .915;
xline(corner,'--','LineWidth',2)
grid on
legend('Non-Filtered','Filtered','Corner Frequency')
ax = gca;
ax.FontSize = 16;

% -- Sample corner frequencies of rock10 --
subplot(1,2,2) 
RMSE.rock(1) = NaN;
test_frequencies = .1:.1:4;
plot(test_frequencies,RMSE.rock,'-or')
grid on
ylabel('RMSE','FontSize',14);
xlabel('<--- More Filtering   [Cycles/Day]   Less Filtering --->','FontSize',14);
title('Sample Corner Frequency','FontSize',14);
ax = gca;
ax.FontSize = 16;

%% --- G15-2208 Filtered @ Different Corner Frequenices --- 
clear all; close all; clc;

% -- Directory -- 
addpath('/Users/parkerwilkerson/Desktop/test_data/GPS/speed/');
Ice15 = readtable('G15_2208.csv');

% -- Clean data --
clean_x = Ice15.X_Vel(~isnan(Ice15.X_Vel));
clean_y = Ice15.Y_Vel(~isnan(Ice15.Y_Vel));
idx = find(~isnan(Ice15.Y_Vel));
clean_date = Ice15.Dates(idx);

% -- Input sampling rate and our testing corner frequnecies -- 
test_frequencies = [0.5,0.9,1.5];
fs = 1/15;
fd = fs*86400;

% -- Apply all corner frequncies to our time-series -- 
for i = 1:length(test_frequencies)
    current_sample = test_frequencies(i);
    [B,A] = butter(4,[current_sample]/(fd/2),'low');
    % -- data --
    Ice15_X = filtfilt(B,A,clean_x);
    Ice15_Y = filtfilt(B,A,clean_y);
    data4store15 = sqrt((Ice15_X.^2)+(Ice15_Y.^2));
    Ice15_Total(:,i) = data4store15(:);
end

% -- Plot data -- 
% sp 1
subplot(3,1,1) 
plot(Ice15.Dates,Ice15.Speed,'.','Color',[0.1569 0.6667 0.9451])
hold on 
plot(clean_date,Ice15_Total(:,1),'-k','LineWidth',1.5)
xlim([datetime(2022,09,02,00,00,00) datetime(2022,10,20,00,00,00)])
grid on
ylabel('Speeds [m/d]','FontSize',16);
ax = gca;
ax.FontSize = 15;
ylim([0 3])
title('Corner Frequency = 0.5')
% sp 2
subplot(3,1,2) 
plot(Ice15.Dates,Ice15.Speed,'.','Color',[0.1569 0.6667 0.9451])
hold on 
plot(clean_date,Ice15_Total(:,2),'-k','LineWidth',1.5)
xlim([datetime(2022,09,02,00,00,00) datetime(2022,10,20,00,00,00)])
grid on
ylabel('Speeds [m/d]','FontSize',16);
ax = gca;
ax.FontSize = 15;
ylim([0 3])
title('Corner Frequency = 0.9')
% sp 3
subplot(3,1,3) 
plot(Ice15.Dates,Ice15.Speed,'.','Color',[0.1569 0.6667 0.9451])
hold on 
plot(clean_date,Ice15_Total(:,3),'-k','LineWidth',1.5)
xlim([datetime(2022,09,02,00,00,00) datetime(2022,10,20,00,00,00)])
grid on
ylabel('Speeds [m/d]','FontSize',16);
ax = gca;
ax.FontSize = 15;
ylim([0 3])
title('Corner Frequency = 1.5')

%% --- Figure: Ice11-2208 with speed-ups and rain and temp ---
clear all; close all; clc;

% -- Needed files: Ice11 speeds, Ice11's rain and temp, Ice11's peaks --
addpath('/Users/parkerwilkerson/Desktop/test_data/GPS/filtered/');
Ice11 = readtable('G11_2208_filt.csv');
addpath('/Volumes/volume/CLEAN_ORGANIZED/Data/weather/SK/model_data_used_for_thesis/precip/');
precip = readtable('precip11_2208.csv');
addpath('/Volumes/volume/CLEAN_ORGANIZED/Data/weather/SK/model_data_used_for_thesis/temp/');
temp = readtable('temp11_2208.csv');
addpath('/Volumes/volume/CLEAN_ORGANIZED/Data/weather/SK/model_data_used_for_thesis/MWE/');
MWE = readtable('MWE11_2208.csv');
addpath('/Users/parkerwilkerson/Desktop/test_data/GPS/analyzed_data');
load('data_peaks.mat');

% -- Ice11 color --
Ice11_color = [0.8353 0.6235 0.2196];

% -- Date range to plot --
date1 = datetime(2022,09,02,00,00,00);
date2 = datetime(2022,10,20,00,00,00);

subplot(3,1,1)
plot(Ice11.clean_date,Ice11.filt_speed,'.','Color',Ice11_color)
hold on
title('Speed [m/d]')
xline(data_peaks.G11_2208.SpeedPeakX,'--','linewidth',1.5)
grid on
xlim([date1 date2])
ax = gca;
ax.FontSize = 15;
ylim([0 5])

subplot(3,1,2)
plot(precip.time,(precip.runoff/3)*1000,'-b','LineWidth',1.5) % <--- From [m/3hr] to [mm/h]
hold on
title('Rain Rate [mm/h]')
xline(data_peaks.G11_2208.SpeedPeakX,'--','linewidth',1.5)
xlim([date1 date2])
ax = gca;
ax.FontSize = 15;
ylim([0 12])
grid on

subplot(3,1,3)
plot(temp.time,temp.runoff-273.15,'-m','LineWidth',1.5) % <--- From [kelvin] to [c]
hold on
title('Temperature [c]')
xline(data_peaks.G11_2208.SpeedPeakX,'--','linewidth',1.5)
xlim([date1 date2])
ax = gca;
ax.FontSize = 15;
ylim([-5 15])
grid on


