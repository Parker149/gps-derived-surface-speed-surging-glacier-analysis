function site_MWE = loadMWE(dataDir)

    % Get all CSV files in the directory
    VelocityFiles = dir(fullfile(dataDir, '*.csv'));
    
    % Preallocate output as a struct
    site_MWE = struct();
    
    for g = 1:length(VelocityFiles)
        
        % Extract filename without extension
        dotLocation = strfind(VelocityFiles(g).name, '.');
        name = VelocityFiles(g).name(1:dotLocation(end)-1);

        % Full file path
        filePath = fullfile(VelocityFiles(g).folder, VelocityFiles(g).name);
        
        % Read table and store using dynamic field name
        site_MWE.(name) = readtable(filePath);
    end
end