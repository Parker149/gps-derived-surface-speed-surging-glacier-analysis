clear all; close all; clc;

% -- Point script to directory with GPS speed data in .csv format --
addpath('/Volumes/volume/The_GPS_Archive/Pipe_Line/SitKusa/Unfiltered_Velocities/');

% -- Read in speed data --
Speed = readtable('GNSS_Velocity.csv');

% -- Collected needed variables --
VX = Speed.X_Vel;
VY = Speed.Y_Vel;
ts1 = datenum(Speed.Dates);

% -- Clean data --
valid = isfinite(VX) & isfinite(VY);
VX1 = VX(valid);
VY1 = VY(valid);
tsu1 = ts1(valid);
clean_date = datetime(tsu1,'ConvertFrom','datenum');

% -- Input sampling rate of GPS data in seconds --
sampling_rate_seconds = 15; % <------ input here
fs = 1/sampling_rate_seconds;
fd = fs*86400;

%% --- Determine Filter Design Parameters ---

% -- Select corner frequnecy in [cycles/day] --
corner_freq = .915; % <----- input here

% -- Order of butterworth filter --
butter_order = 4; % <----- input here

%% --- Create And Apply Filter ---

% -- Create filter (MUST input whether high or low pass filter) -- 
[B,A] = butter(butter_order,[corner_freq]/(fd/2),'low'); % <----- input here

% -- Apply filter --
filtered_vx = filtfilt(B,A,VX1);
filtered_vy = filtfilt(B,A,VY1);

% -- Combine filtered easting and northing velocities into speed vector -- 
filt_speed = sqrt((filtered_vx.^2)+(filtered_vy.^2));

% -- Create table for .csv --
T = table(clean_date,filtered_vx,filtered_vy,filt_speed);

%% --- Plot Visualizations Of Frequency Filtering ---

% -- Pre and post filtered speeds --
figure(1)
plot(Speed.Dates,Speed.Speed,'-r','LineWidth',2)
hold on
plot(clean_date,filt_speed,'-b','LineWidth',2)
xlabel('Date','FontSize',14)
ylabel('Speed [m/d]','FontSize',14)
grid on
title('GPS Speed')
legend('Pre-Filtering','Post-Filtering')
ax = gca;
ax.FontSize = 16;

% -- Frequency domain of easting velocities pre and post filtering -- 
figure(2)
% pre filter domain & plot
NX = length(tsu1);        
YX = fft(VX1);           
P2X = abs(YX/NX);            
P1X = P2X(1:floor(NX/2)+1);   
P1X(2:end-1) = 2*P1X(2:end-1); 
fX = fd*(0:(NX/2))/NX;
plot(fX, P1X,'-r','LineWidth',2)
hold on
% post filter domain & plot
NX = length(tsu1);        
YX = fft(filtered_vx);           
P2X = abs(YX/NX);            
P1X = P2X(1:floor(NX/2)+1);   
P1X(2:end-1) = 2*P1X(2:end-1); 
fX = fd*(0:(NX/2))/NX;
plot(fX, P1X,'-b','LineWidth',2)
% make plot look good
legend('Pre-Filtering','Post-Filtering')
xlabel('Frequency [cycles per day]','FontSize',16);
ylabel('Amplitude','FontSize',16);
title('Frequency Domain of EASTING Velocity','FontSize',18);
xlim([0 5.5])
ylim([0 .22])
grid on
ax = gca;
ax.FontSize = 18;

% -- Frequency domain of northing velocities pre and post filtering -- 
figure(3)
% pre filter domain & plot
NX = length(tsu1);        
YX = fft(VY1);           
P2X = abs(YX/NX);            
P1X = P2X(1:floor(NX/2)+1);   
P1X(2:end-1) = 2*P1X(2:end-1); 
fX = fd*(0:(NX/2))/NX;
plot(fX, P1X,'-r','LineWidth',2)
hold on
% post filter domain & plot
NX = length(tsu1);        
YX = fft(filtered_vy);           
P2X = abs(YX/NX);            
P1X = P2X(1:floor(NX/2)+1);   
P1X(2:end-1) = 2*P1X(2:end-1); 
fX = fd*(0:(NX/2))/NX;
plot(fX, P1X,'-b','LineWidth',2)
% make plot look good
legend('Pre-Filtering','Post-Filtering')
xlabel('Frequency [cycles per day]','FontSize',16);
ylabel('Amplitude','FontSize',16);
title('Frequency Domain of Northing Velocity','FontSize',18);
xlim([0 5.5])
ylim([0 .22])
grid on
ax = gca;
ax.FontSize = 18;

%% --- Create A New .csv for Filtered GPS Speeds ---

% -- Input name for file -- 
writetable(T, 'Filtered_GPS_Speeds.csv'); % <----- input here



