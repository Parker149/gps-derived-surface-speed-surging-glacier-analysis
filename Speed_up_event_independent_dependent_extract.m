%% --- Script Used To Extract Independent And Dependent Variables Around Speed-Up Events ---
clearvars; close all; clc;

% -- Point script to directory where Detrended Data is stored --
addpath('/Users/parkerwilkerson/Desktop/test_data/GPS/');
load('detrend_data');
V_names = fieldnames(detrend_data);

% -- Point script to directory where data_peaks.mat is stored --
addpath('/Users/parkerwilkerson/Desktop/test_data/GPS/analyzed_data/');
load('data_peaks');

% -- Point script to directory where functions are stored --
addpath('/Volumes/volume/final_code_FINAL/Functions/');

% -- Load Rain Data --
dataDir = '/Volumes/volume/CLEAN_ORGANIZED/Data/weather/SK/model_data_used_for_thesis/precip/';
site_P = loadRain(dataDir);
R_names = fieldnames(site_P);

% -- Load Rain Data --
dataDir = '/Volumes/volume/CLEAN_ORGANIZED/Data/weather/SK/model_data_used_for_thesis/temp/';
site_T = loadTemp(dataDir);
T_names = fieldnames(site_T);

% -- Load Rain Data --
dataDir = '/Volumes/volume/CLEAN_ORGANIZED/Data/weather/SK/model_data_used_for_thesis/MWE/';
site_MWE = loadTemp(dataDir);
MWE_names = fieldnames(site_MWE);

%% --- Preform Data Extraction ---
clc
for ii = 1:length(V_names)
    working_precip = site_P.(R_names{ii});
    working_temp = site_T.(T_names{ii});
    working_MWE = site_MWE.(MWE_names{ii});
    working_detrend = detrend_data.(V_names{ii});
    working_peaks = data_peaks.(V_names{ii});  
    for CM = 1:length(working_peaks.SpeedPeakX)
        % Corresponding Peak Rain Event and Date
        spot_end = working_peaks.SpeedPeakX(CM);
        spot_start = spot_end - days(4);
        idx = find(working_precip.time >= spot_start & working_precip.time <= spot_end);
        datadata = working_precip.runoff(idx);
        datadata_X = working_precip.time(idx);
        idty = max(datadata);
        idty_X = find(datadata == idty);
        x_value_precip = datadata_X(idty_X);
        % duration of rain event 
        thresh = 0.0005;
        left_idx = find(working_precip.time >= working_precip.time(1) & working_precip.time <= x_value_precip);
        right_idx = find(working_precip.time >= x_value_precip & working_precip.time <= working_precip.time(end));
        left_rain = working_precip.runoff(left_idx);
        right_rain = working_precip.runoff(right_idx);
        edge_left_idx = find(left_rain <= thresh, 1, 'last');
        if isempty(edge_left_idx)
            t_left = working_precip.time(left_idx(1));  
        else
            t_left = working_precip.time(left_idx(edge_left_idx));
        end
        edge_right_idx = find(right_rain <= thresh, 1, 'first');
        if isempty(edge_right_idx)
            t_right = working_precip.time(right_idx(end));  
        else
            t_right = working_precip.time(right_idx(edge_right_idx));
        end
        peak_duration = t_right - t_left;
        rain_volume_idx = find(working_precip.time >= t_left & working_precip.time <= t_right);
        rain_volume = working_precip.runoff(rain_volume_idx);
        event_precip_volume = sum(rain_volume);
        % peak temp within 4 days of V peak 
        idx_T = find(working_temp.time >= spot_start & working_temp.time <= spot_end);
        datadata_T = working_temp.runoff(idx);
        datadata_X_T = working_temp.time(idx);
        idty_T = max(datadata_T);
        idty_X_T = find(datadata_T == idty_T);
        x_value_temp = (datadata_X_T(idty_X_T));
        % Lag Time of Velocity and Rain
        lag_1 = spot_end - x_value_precip;
        % Precent Increase In velocity
        idx_prec = find(spot_end == working_detrend.x);
        if ismember(V_names{ii}, {'G14_2008', 'G12_2008', 'G15_2106'})
            max_vel = working_detrend.y(idx_prec);
            backgrd = working_detrend.data_spline(idx_prec);
            prec_inc = abs((max_vel - backgrd) / backgrd) * 100;
        else
            max_vel = working_detrend.y(idx_prec);
            backgrd = nanmean(working_detrend.y);
            prec_inc = abs((max_vel - backgrd) / backgrd) * 100;
        end
        % duration of speed up event 
        dt = working_detrend.x;
        v  = working_detrend.y;
        pre_peak  = spot_end - hours(1);
        post_peak = spot_end + hours(1);
        pre_window  = [pre_peak - days(4), pre_peak];
        post_window = [post_peak, post_peak + days(4)];
        pre_idx  = dt >= pre_window(1)  & dt <= pre_window(2);
        post_idx = dt >= post_window(1) & dt <= post_window(2);
        bin = minutes(60);
        TT_pre  = retime(timetable(dt(pre_idx),  v(pre_idx)),  'regular','mean','TimeStep',bin);
        TT_post = retime(timetable(dt(post_idx), v(post_idx)), 'regular','mean','TimeStep',bin);
        pre_vel = TT_pre.Var1;
        pre_time_binned = TT_pre.Time;
        pre_idx_stop = length(pre_vel);
        for i = length(pre_vel)-1:-1:1
            if pre_vel(i) >= pre_vel(i+1)
                pre_idx_stop = i+1;
                break
            end
        end
        pre_stop_time = pre_time_binned(pre_idx_stop);
        post_vel = TT_post.Var1;
        post_time_binned = TT_post.Time;
        post_idx_stop = 1;
        for i = 1:length(post_vel)-1
            if post_vel(i+1) >= post_vel(i)
                post_idx_stop = i;
                break
            end
        end
        post_stop_time = post_time_binned(post_idx_stop);
        duration_event = post_stop_time - pre_stop_time;
        % speeding up or slowing down before speed up
        pre_trend = pre_stop_time - days(2);
        idx_trend = find(working_detrend.x >= pre_trend & working_detrend.x <= pre_stop_time);
        trend_data = working_detrend.data_spline(idx_trend);
        trend_data_x = decyear(working_detrend.x(idx_trend));
        p = polyfit(trend_data_x,trend_data,1);
        trendy = p(1)/365.25;
        % rate of temperature change before speed up event
        temp_trend_idx = find(working_temp.time >= pre_trend & working_temp.time <= pre_stop_time);
        temp_trend_data = working_temp.runoff(temp_trend_idx);
        temp_trend_data_x = decyear(working_temp.time(temp_trend_idx));
        p_t = polyfit(temp_trend_data_x,temp_trend_data,1);
        temp_trend = p_t(1) / (365.25 * 24);
        % peak MWE
        idx_MWE = find(working_MWE.time >= spot_start & working_MWE.time <= spot_end);
        datadata_MWE = working_MWE.runoff(idx_MWE);
        datadata_X_MWE = working_MWE.time(idx_MWE);
        idty_MWE = max(datadata_MWE);
        idty_X_MWE = find(datadata_MWE == idty_MWE);
        x_value_MWE = datadata_X_MWE(idty_X_MWE);
        % time elasped from previous veloicty event
        if CM == 1 
            time_between = NaN;
        else
            current_peak_time = working_peaks.SpeedPeakX(CM);
            prev_peak_time = working_peaks.SpeedPeakX(CM-1);
            place_holder = current_peak_time - prev_peak_time;
            time_between = days(place_holder);
        end 
        % Xcross 
        time_1 = t_left + hours(2);
        time_2 = post_stop_time + hours(2); 
        MWE_id = find(working_MWE.time >= time_1 & working_MWE.time <= time_2);
        Velocity_id = find(working_detrend.x >= time_1 & working_detrend.x <= time_2);
        melt_x = working_MWE.time(MWE_id);
        melt_y = working_MWE.runoff(MWE_id);
        v_X_x = working_detrend.x(Velocity_id);
        v_X_y = working_detrend.detrend_y(Velocity_id);
        if strcmp(V_names{ii}, 'G14_2008') || strcmp(V_names{ii}, 'G12_2008') || strcmp(V_names{ii}, 'G11_2408')
            valid_idx = ~isnan(v_X_y);
            v_X_x = v_X_x(valid_idx);
            v_X_y = v_X_y(valid_idx);
        end
        dec_Mx = decyear(melt_x); 
        dec_Vx = decyear(v_X_x);
        melt_interp = interp1(dec_Mx, melt_y, dec_Vx, 'linear', NaN);
        numNaNs = sum(isnan(melt_interp));
        valid = ~isnan(melt_interp);
        if any(valid)
            melt_interp_t = melt_interp(valid);
            v_X_y_t = v_X_y(valid);
            trim_dec = dec_Vx(valid);
            dc_V = v_X_y_t - mean(v_X_y_t);
            dc_M = melt_interp_t - mean(melt_interp_t);
            cc = xcorr(dc_V, dc_M, 'coeff'); 
            [maxValue, maxIndex] = max(cc);
            numSteps = length(dc_V);
            lags = (-numSteps+1):(numSteps-1);
            dt_sec = mean(diff(trim_dec)) * (365.25*24*60*60);
            hours1 = lags * dt_sec / 3600;                      
            lag = hours1(maxIndex);
        else
            warning('No valid overlapping data for this window — skipping cross-correlation');
            melt_interp_t = [];
            v_X_y_t = [];
            trim_dec = [];
            dc_V = [];
            dc_M = [];
            cc = [];
            lag = NaN;
            maxValue = NaN;
        end
        % Compile Data
        working_peaks.TimeBtwnPeaks_days(CM) =  time_between(:);
        working_peaks.V_duration(CM) = hours(duration_event(:));
        working_peaks.Xval_PkPrecipRt(CM) = x_value_precip(:);
        working_peaks.PkPrecipRt(CM) = (idty(:)/3)*1000;
        working_peaks.PrecipDuration_hours(CM) = hours(peak_duration(:));
        working_peaks.Precip_volume(CM) = event_precip_volume(:);
        working_peaks.pre_V_trend(CM) = trendy;
        working_peaks.lag_time_precip_Rt(CM) = lag_1(:);
        working_peaks.precent_inc_vel(CM) = prec_inc(:);
        working_peaks.MaxTemp(CM) = idty_T(:)-273.15;
        working_peaks.MaxTemp_x(CM) = x_value_temp;
        working_peaks.TempTrend(CM) = temp_trend;
        working_peaks.MaxMWE(CM) = idty_MWE;
        working_peaks.MaxMWE_x(CM) = x_value_MWE;
        working_peaks.Xcross_MWE(CM) = maxValue;
        working_peaks.lag_hours_from_Xcross(CM) = lag;
        clear p pre_trend trend_data trend_data_x
    end
    Extracted_Variables.(V_names{ii}) = working_peaks;
end

%% --- Save Data as Matlab Struct ---

% -- Save data to desired directory --
saveDir = '/Users/parkerwilkerson/Desktop/test_data/GPS/analyzed_data/'; % <------ input here [directory path]
save(fullfile(saveDir, 'Extracted_Variables.mat'), 'Extracted_Variables'); % <------ input here [file name]