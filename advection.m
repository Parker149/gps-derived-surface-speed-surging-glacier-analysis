%% -- Advection Analysis --
clear all; close all; clc;

% -- GPS record for comparision -- 
addpath('/Volumes/volume/CLEAN_ORGANIZED/Data/The_GPS_Archive/SK/Filtered_Velocities_FINAL/');
GPS4vel = readtable('G12_2008_filt.csv');

% -- Sampling locations for raster values -- 
addpath('/Volumes/volume/CLEAN_ORGANIZED/CautoRift/advection_analysis/GPS_Sample_Locations/Ice12_2008_50m-interval/')
S = shaperead('Ice12_2008_50m-interval.shp');
x_shp = [S.X]';
y_shp = [S.Y]';

% -- How far did the GPS station travel based on the 50m samples -- 
distance_traveled = sqrt((x_shp(end)-x_shp(1))^2 + (y_shp(end)-y_shp(1))^2);

% -- Load all rasters -- 
rasterFolder = '/Volumes/volume/CLEAN_ORGANIZED/CautoRift/advection_analysis/velocity/jukes_20_9to10/';
rasterFiles = dir(fullfile(rasterFolder, 'velocity_*.tif'));

% -- Sampling locations for raster -- 
X4raster = linspace(0,distance_traveled,length(x_shp));
num_points = length(GPS4vel.Dates);
dist_from_deploy = linspace(0,distance_traveled,num_points);

% -- Initialize table --
SampledTable = table(x_shp, y_shp, 'VariableNames', {'x', 'y'});

% -- Loop through all rasters and sample at each location -- 
for k = 1:length(rasterFiles)
    % Full path to current raster
    rasterPath = fullfile(rasterFolder, rasterFiles(k).name);
    % Extract date string (characters 10 to 26 after 'velocity_')
    dateStr = rasterFiles(k).name(10:26); % '20210810_20210830'
    % Read raster 
    [one, R] = geotiffread(rasterPath);
    % Extract layer 3 and convert to m/day
    layer3 = one(:,:,3) / 365;
    % Create X and Y grids using meshgrid
    [cols, rows] = meshgrid(1:R.RasterSize(2), 1:R.RasterSize(1)); % col = x, row = y in image coords
    [X, Y] = intrinsicToWorld(R, cols, rows);
    % Linear interpolate 
    sampledValues = interp2(X, Y, double(layer3), x_shp, y_shp);
    % Store data 
    SampledTable.(dateStr) = sampledValues;
end

% -- Covert to table for ease of indexing
samp = table2array(SampledTable);


% -- If a column, a rasters worth of data, is 50% NaNs or higher, make itall NaNs to ignore it --
nanThreshold = 0.5 * size(samp, 1);
for col = 1:size(samp, 2)
    numNaNs = sum(isnan(samp(:, col)));
    if numNaNs > nanThreshold
        samp(:, col) = NaN;
    end
end

% -- If one point to another has a > 10 m/d diff than that whole column is removed --
d = abs(diff(samp(:,3:size(samp,2))));
badCols = any(d > 10, 1);
samp(:, 2 + find(badCols)) = NaN;

% -- Remove columns that are entierly NaNs --
colsToRemove = false(1,size(samp,2));
for col = 3:size(samp,2)   
    if all(isnan(samp(:,col)))
        colsToRemove(col) = true;
    end
end
samp(:,colsToRemove) = [];

% -- Create average cauto transect --  
for i = 1:length(x_shp)
    spat_aves(i) = nanmean(samp(i,3:size(samp,2)));
end

% -- Plotting -- 
h1 = plot(X4raster, samp(:,3:end), '--', 'LineWidth', 1.5, 'Color', [0.5 0.5 0.5]);
hold on
h2 = plot(X4raster, spat_aves, 'k-', 'LineWidth', 2);
h3 = plot(dist_from_deploy, GPS4vel.filt_vtotal, '-', ...
          'Color', [0.5020 0.0667 0.7569], 'LineWidth', 2);
xlim([0 distance_traveled])
ylim([0 25])
grid on
ylabel('Speed [m/d]','FontSize',16)
xlabel('Distance From Station Deployment [m]','FontSize',16)
ax = gca;
ax.FontSize = 16;
legend([h1(1) h2 h3], ...
       'Individual CautoRIFT Profiles', ...
       'Averaged CautoRIFT Speeds', ...
       'Ice12-2008')

% --- Variation Of Transect --- 
% what is the ave raster value 
ave_raster = mean(spat_aves);
% what is the ave GPS value 
ave_GPS = mean(GPS4vel.filt_vtotal);
% what is the greatest difference between the ave raster value to a raster value 
raster_max_diff = max(abs(ave_raster - spat_aves));
% what is the greatest difference between the ave GPS value to a GPS value 
GPS_max_diff = max(abs(ave_GPS - GPS4vel.filt_vtotal));
% what is ratio of the max differences to the ave GPS value 
GPS_max_diff_ratio = GPS_max_diff / ave_GPS
raster_max_diff_ratio = raster_max_diff / ave_GPS
