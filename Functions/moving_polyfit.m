function slopes = moving_polyfit(x, y, window_size,record_int,portion)

%Flex = takes the median of filtered time varibale differences, which
    %should be the system record interval and then divides the window size by
    %the median value. 

    x = x(:);
    y = y(:);
    
    % Initialize the output vector to store the slopes
    slopes = NaN * ones(size(x));  % Use NaN to indicate no data for some points

    % determine minimum threshold of points needed for polyfit
    threshold = window_size(1)/record_int; 
    
    for i = 1:length(x)
        
        window_start = x(i);
        window_end = window_start + window_size;
        
        window_indices = (x >= window_start) & (x < window_end);
        
        x_window = x(window_indices);
        y_window = y(window_indices);
        
        if length(x_window) >= portion*threshold % threshold for min points required 
              
        p = polyfit(x_window, y_window, 1);
 
            slopes(i) = p(1);  % only first coefficient (degree 1)
        end
    end



    
end