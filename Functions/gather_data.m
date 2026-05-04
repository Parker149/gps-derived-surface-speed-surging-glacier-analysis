%% --- Helper function to collect all data from a dataset struct ---
function [X, Y] = gather_data(data_struct, sites, x_var, y_var)
    X = [];
    Y = [];    
    for i = 1:length(sites)
        T = data_struct.(sites{i});
        % --- X variable ---
            X = [X; T.(x_var)];
        % --- Y variable ---
            Y = [Y; T.(y_var)];
    end
end