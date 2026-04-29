clear all; close all; clc;

% -- Point script to directory where functions are stored --
% -- Needed functions: [Decyear_to_Datetime.m, ll2utm.m, & moving_polyfit.m] --  
addpath('/Volumes/volume/final_code_FINAL/Functions/');

% -- Point script to directory with GPS data in .csv format --
addpath('/Users/parkerwilkerson/Desktop/test_data/GPS/base/');

% -- Read in GPS .csv --
GPS = readtable('all_positions_G15_2308.csv');

% -- Extract lat, lon, & datetime variables from GPS data -- 
lat=GPS.latitude_decimal_degree;
lon=GPS.longitude_decimal_degree;
time = GPS.datetimes;

% -- Create XY UTM and decyear from data --
[x,y,zone] = ll2utm(lat,lon);
time_dec = decyear(time);

% -- Plot UTM -- 
figure(1)
plot(x,y,'.r')
xlabel('UTM Easting','FontSize',14)
ylabel('UTM Northing','FontSize',14)
grid on
title('UTM Positions')
ax = gca;
ax.FontSize = 16;

%% --- Clean Data Before Applying Moving Window Polyfit --- 

% -- remove redundant values --  
[C,IA] = unique(time_dec);
clean_dec = time_dec(IA);
clean_dat = time(IA);
clean_x = x(IA);
clean_y = y(IA);
number_of_redundant_values_removed = length(time) - length(clean_y)

% -- Some GPS units have recordings after/ before being deployed on the glacier --
idx = find(clean_y < 6610000);
clean_dec(idx) = NaN; 
clean_dat(idx) = NaT;
clean_x(idx) = NaN;
clean_y(idx) = NaN;

% -- remove NaNs -- 
bad = isnan(clean_dec) | isnan(clean_x) | isnan(clean_y);
clean_dec = clean_dec(~bad);
clean_dat = clean_dat(~bad);
clean_x   = clean_x(~bad);
clean_y   = clean_y(~bad);
%% --- Determine Inputs For Smoothing ---

% -- Window size for smoothing window -- 
number_of_days = 1; % <----- input here
window_size = number_of_days / 365.25;

% -- Minimum threshold of window needed to process data -- 
portion = .5; % <----- input here

% -- Automatically determine sampling rate of GPS system in seconds and store as a decimal year --
raw_samp_rate = median(diff(clean_dat));
display(raw_samp_rate)
record_int_a = floor(seconds(raw_samp_rate));
record_int = record_int_a / (365.25 * 24 * 60 * 60);

%% --- Data Trimming ---

% READ ME: if there is a period of data for which you do not wish to
% analyze alter this section. If you do not want to preform any data
% trimming, DON'T run this section. 

% The Study this code was developed for did not analyze any GPS data after
% November 15th or before June 1st.

% -- Input date range of data you wish to move forward with --
start = clean_dat(1);
endd = datetime(2023,11,15,00,00,00);

% -- Preform data trimming --
idx = find(clean_dat >= start & clean_dat <= endd);
clean_dec = clean_dec(idx);
clean_dat = clean_dat(idx);
clean_x = clean_x(idx);
clean_y = clean_y(idx);

%% --- Apply Moving Window Polyfit ---

% -- Call function and hand the function needed variables -- 
% -- Creates northing and easting velocity vectors separately -- 
d_x_velocity = moving_polyfit(clean_dec,clean_x,window_size,record_int,portion);
d_y_velocity = moving_polyfit(clean_dec,clean_y,window_size,record_int,portion);

% -- Convert velocities from [meters per year] -> [meters per day] --
d_x_velocity = d_x_velocity./365;
d_y_velocity = d_y_velocity./356;

%% --- Final Data Preperation ---

% -- Interpolate data to regular intervals based on recording interval -- 
new_dec = clean_dec(1):record_int:clean_dec(end);

% -- Determine maximum time gap to preform interpolation over -- 
number_of_hours = 12; % <----- input here
gap_thresh = number_of_hours / (24 * 365.25);  
gap_indices = find(diff(clean_dec) > gap_thresh);
mask = true(size(new_dec));

% -- Preform interpolation & set large time gaps to NaNs -- 
for i = 1:length(gap_indices)
    t_start = clean_dec(gap_indices(i));
    t_end = clean_dec(gap_indices(i)+1);
    mask(new_dec > t_start & new_dec < t_end) = false;
end
new_x = interp1(clean_dec, d_x_velocity, new_dec, 'linear');
new_y = interp1(clean_dec, d_y_velocity, new_dec, 'linear');
new_x(~mask) = NaN;
new_y(~mask) = NaN;

% -- Calculate along-flow speed as magnitude X & Y vector sum --
d_velocity=sqrt((new_x.^2)+(new_y.^2));

% -- Final variables to be saved to new .csv --
Dates = (Decyear_to_Datetime(new_dec'))+hours((number_of_days*24)/2); % Ensure data is centered to window
DecDates = decyear(Dates);
X_Vel = new_x';
Y_Vel = new_y';
Speed = d_velocity';
T = table(Dates,DecDates,X_Vel,Y_Vel,Speed);

% -- Plot speed over time --
figure(2)
plot(Dates,Speed,'.r')
xlabel('Dates','FontSize',14)
ylabel('Speed [m/d]','FontSize',14)
grid on
title('Processed GPS Speeds Over Time')
ax = gca;
ax.FontSize = 16;

%% --- Create A New .csv for GPS Speeds ---

% -- Input name for file -- 
writetable(T, 'G15_2308.csv'); % <----- input here


