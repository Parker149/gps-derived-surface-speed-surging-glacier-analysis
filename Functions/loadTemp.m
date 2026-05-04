function site_T = loadTemp(dataDir)

    % Get all CSV files in the directory
    VelocityFiles = dir(fullfile(dataDir, '*.csv'));
    
    % Preallocate output as a struct
    site_T = struct();
    
    for g = 1:length(VelocityFiles)
        
        % Extract filename without extension
        dotLocation = strfind(VelocityFiles(g).name, '.');
        name = VelocityFiles(g).name(1:dotLocation(end)-1);

        % Full file path
        filePath = fullfile(VelocityFiles(g).folder, VelocityFiles(g).name);
        
        % Read table and store using dynamic field name
        site_T.(name) = readtable(filePath);
    end
end