# gps-derived-surface-speed-surging-glacier-analysis

Run the following processing pipeline: 

Step 1.
- process_GPS_and_convert_to_speed.m

Step 2. 
- northing_easting_velocity_frequency_analysis.m

Step 3.
- butterworth_frequency_filter_of_GPS_speeds.m

Step 4.
- remove_background_speed_trend.m

Step 5.
- speed_up_event_detection.m

Step 6. 
- speed_up_event_independent_dependent_extract.m

Step 7.
- speed_profile_extract.m

Once the above pipeline has been completed the following scripts can be run in any order: 
- corr_heat_map.m
- fit_scatter_plots.m
- plots_for_thesis.m
- displacement_calculator.m
- rain_accumulation_profiles.m
- temporal_Cov_Fig.m
- advection.m 
