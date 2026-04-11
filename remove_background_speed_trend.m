%% --- Code Originally Developed By Ellyn Enderlin Of Boise State University ---

clearvars; close all; clc;

% -- Point script to directory where functions are stored --
addpath('/Volumes/volume/final_code_FINAL/Functions/');

% -- Point to directory where GPS speed data is stored --
dataDir = '/Volumes/volume/The_GPS_Archive/Pipe_Line/SitKusa/Filtered_Velocities_Final/';

% -- Load all data and create name for looping -- 
site_V = load_data_and_create_name(dataDir);

%% --- Moving Minimum Within Multi-Day Window Then Spline ---
 
detrend_data = struct();

% -- Determine window size in days to preform detrending over --
days = 6; % <------ input here

disp('using splines fit to modified minima to detrend velocities');
%iterate through the datasets
for p = 1:length(site_V)

    % create data array
    siteName = site_V{p};

    %initial data
    x = eval(site_V{p}).Dates;
    y = eval(site_V{p}).filt_vtotal;
    dt = diff(x); dt_sec = seconds(dt);
    dt_ref = mode(dt_sec);


    %fill-in time gaps with NaNs so the moving window size is uniform
    gap_inds = find(dt_sec>dt_ref);
    if isempty(gap_inds)
        disp('continuous record!');
        filled_x = x; filled_y = y;
    else
        disp('filling gaps with NaNs at the data sampling interval');
        filled_x = x(1:gap_inds(1)); filled_y = y(1:gap_inds(1));
        for j = 1:length(gap_inds)
            if j == length(gap_inds)
                end_ind = length(x);
            else
                end_ind = gap_inds(j+1);
            end

            remainder = mod(seconds(x(gap_inds(j)+1)-x(gap_inds(j))),dt_ref);
            if remainder > 0
                filled_sec = [x(gap_inds(j))+seconds(dt_ref):seconds(dt_ref):x(gap_inds(j)+1)-seconds(remainder)]';
            else
                filled_sec = [x(gap_inds(j))+seconds(dt_ref):seconds(dt_ref):x(gap_inds(j)+1)-seconds(dt_ref)]';
            end

            %fill in the time & data gap
            filled_x = [filled_x; filled_sec; x(gap_inds(j)+1:end_ind)];
            filled_y = [filled_y; NaN(size(filled_sec)); y(gap_inds(j)+1:end_ind)];
            clear filled_sec remainder end_ind;
        end
    end

    %find the minimum within a moving window
    window_halfwidth = round((((60/dt_ref)*60*24)*days)/2); %(15*4*60*24) = (1 day * desired days of full window)/2
    min_ys = NaN(size(length(filled_x))); min_inds = NaN(size(length(filled_x)));
    for j = 1:length(filled_x)
        %define moving window boundaries
        if j <= window_halfwidth; start_ind = 1; else; start_ind = j-window_halfwidth; end
        if j >= length(filled_x)-window_halfwidth; end_ind = length(filled_x); else; end_ind = j+window_halfwidth; end

        %find the minimum and its index
        [min_y,min_ind] = min(filled_y(start_ind:end_ind));

        %make sure only one time is recorded
        min_ys(j) = min_y(1); min_inds(j) = start_ind-1+min_ind(1);

        clear start_ind end_ind min_y min_ind;
    end

    %make sure the first and last observations are included in the minima
    %for spline fitting purposes
    min_ys = [filled_y(1), min_ys, filled_y(end)];
    min_inds = [1, min_inds, length(filled_y)];

    %isolate the unique minima & identify the corresponding dates
    unique_inds = unique(min_inds);
    unique_vels = filled_y(unique_inds); unique_dates = filled_x(unique_inds);

    %make sure there is at most one minimum per day
    yyyyMMdd = [year(unique_dates),month(unique_dates),day(unique_dates)];
    [unique_days,ia,ic] = unique(yyyyMMdd,'rows');
    for j = 1:length(unique_days)
        vel_sub = unique_vels(ic==j); date_sub = unique_dates(ic==j);
        [~,min_ind] = min(vel_sub);
        min_speeds(j) = vel_sub(min_ind);
        min_dates(j) = date_sub(min_ind);
        yr_start = dateshift(date_sub(min_ind), 'start', 'year');
        nextyr_start = yr_start + calyears(1);
        min_decidates(j) = year(date_sub(min_ind))+(date_sub(min_ind)-yr_start)./(nextyr_start-yr_start);
        clear vel_sub date_sub min_ind *yr_start;
    end

    %if the day before or after is identified as a daily minimum, only keep
    %the lowest value... could be adjusted to look at longer stretches of
    %neighboring days 
    for j = 2:length(min_speeds)-1 
        %compare to day before
        if abs(diff(day(min_dates(j-1:j),'dayofyear'))) == 1 && sum(~isnan(min_speeds(j-1:j))) == 2 %  (change first == 1 to ==2 
            if min_speeds(j) <= min_speeds(j-1)
                min_speeds(j-1) = NaN;
            else
                min_speeds(j) = NaN;
            end
        end

        %compare to day after
        if abs(diff(day(min_dates(j-1:j),'dayofyear'))) == 1 && sum(~isnan(min_speeds(j:j+1))) == 2 % (change first == 1 to ==2 
            if min_speeds(j) <= min_speeds(j+1)
                min_speeds(j+1) = NaN;
            else
                min_speeds(j) = NaN;
            end
        end

    end
    min_dates(isnan(min_speeds)) = []; min_decidates(isnan(min_speeds)) = []; min_speeds(isnan(min_speeds)) = []; 
    
    SS = csape(min_decidates,min_speeds,'variational');

    %evaluate the spline for all datetimes
    %convert datetimes to decimal dates for spline fitting
    B = dateshift(filled_x, 'start', 'year'); % midnight at start of the year
    E = B + calyears(1); % midnight at the end of the year (do not use DATESHIFT)
    Y = year(filled_x);
    filled_decidates = Y + (filled_x-B)./(E-B);
    %evaluate the spline function for each decimal date
    spline_fit = fnval(SS,filled_decidates);

    %plot the results
    figure; set(gcf,'position',[50 50 800 500]);
    subplot(1,2,1);
    plot(x,y,'.r'); hold on;
    xlabel('Date','FontSize',16); ylabel('Velocity [m/d]','FontSize',16');
    plot(min_dates,min_speeds,'+','color',[1 0.5 0],'linewidth',2); hold on;
    ylabel('Velocity [m/d]'); grid on;
    ax = gca;
    ax.FontSize = 18;
    drawnow;
    plot(filled_x,spline_fit,'-k','linewidth',2); hold on;
    subplot(1,2,2);
    plot(filled_x,filled_y-spline_fit,'-b','linewidth',2); hold on;
    ylabel('Velocity [m/d]'); grid on;
    xlabel('Date');
    %title(site_V{p}, 'Interpreter', 'none');
    ax = gca;
    ax.FontSize = 18;
    drawnow;

    final_detrend = filled_y - spline_fit;

    detrend_data.(siteName).x = filled_x;
    detrend_data.(siteName).detrend_y = final_detrend;
    detrend_data.(siteName).data_spline = spline_fit;
    detrend_data.(siteName).y = filled_y;

    %clear variables to prevent inheritance between loops
    clear x y dt* window_halfwidth *_ind* filled_* min_* unique_* yyyyMMdd ia ic B E Y SS spline*; 
end
disp('done detrending!');

%% --- Save Detrended Data As Matlab Struct ---

% -- All data is stored in -> detrend_data <- --
% - x = datetimes
% - detrend_y = detrended speed data
% - data_spline = data spline used to preform detrending
% - y = speed data before detrending 

% -- Save data to desired directory --
saveDir = '/Volumes/volume/'; % <------ input here [directory path]
save(fullfile(saveDir, 'detrend_data.mat'), 'detrend_data'); % <------ input here [file name]