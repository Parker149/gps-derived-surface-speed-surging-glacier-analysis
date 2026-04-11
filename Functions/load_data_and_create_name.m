function site_V = load_data_and_create_name(dataDir)

    VelocityFiles = dir(fullfile(dataDir, '*.csv'));
    site_V = cell(1, length(VelocityFiles));

    for g = 1:length(VelocityFiles)

        % File name
        fileName = VelocityFiles(g).name;

        % Find dot location
        dotLocation = strfind(fileName, '.');

        % Create site name
        siteName = fileName(1:dotLocation(end)-6);
        site_V{g} = siteName;

        % Full file path
        filePath = fullfile(VelocityFiles(g).folder, fileName);

        % Read table
        T = readtable(filePath);

        % Push variable into base workspace
        assignin('base', siteName, T);

    end
end