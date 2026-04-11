clear; close all; clc;

% -- Point script to directory where speed data is stored --
addpath('/Volumes/volume/The_GPS_Archive/SK/all_positions/');

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

% -- Input sampling rate of GPS data in seconds --
sampling_rate_seconds = 15; % <------ input here
fs = 1/sampling_rate_seconds;
fd = fs*86400;

% -- Frequency assessment of easting velocities --
NX = length(tsu1);        
YX = fft(VX1);           
P2X = abs(YX/NX);            
P1X = P2X(1:floor(NX/2)+1);   
P1X(2:end-1) = 2*P1X(2:end-1); 
fX = fd*(0:(NX/2))/NX;      

% -- Frequency assessment of northing velocities --
NY = length(tsu1);        
YY = fft(VY1);           
P2Y = abs(YY/NY);             
P1Y = P2Y(1:floor(NY/2)+1);   
P1Y(2:end-1) = 2*P1Y(2:end-1); 
fY = fd*(0:(NY/2))/NY;  

% -- Easting velocity frequency domain -- 
figure(1)
plot(fX, P1X,'-r','LineWidth',2)
xlabel('Frequency (cycles per day)','FontSize',16);
ylabel('Amplitude','FontSize',16);
title('EASTING Velocity','FontSize',18);
xlim([0 5.5])
ylim([0 .22])
grid on
hold on
ax = gca;
ax.FontSize = 18;

% -- Northing velocity frequency domain -- 
figure(2)
plot(fY, P1Y,'-b','LineWidth',2)
xlabel('Frequency [cycles per day]','FontSize',16);
ylabel('Amplitude','FontSize',16);
title('NORTHING Velocity','FontSize',18);
xlim([0 5.5])
ylim([0 .22])
grid on
hold on
ax = gca;
ax.FontSize = 18;