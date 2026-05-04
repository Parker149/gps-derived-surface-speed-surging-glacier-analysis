function site_V = load_data_and_create_name_RAW(dataDir)

    VelocityFiles = dir(fullfile(dataDir, '*.csv'));
    site_V = cell(1, length(VelocityFiles));

    for g = 1:length(VelocityFiles)

        % File name
        fileName = VelocityFiles(g).name;

        siteName = extractBefore(fileName, '.csv');
        site_V{g} = siteName;

        % Full file path
        filePath = fullfile(VelocityFiles(g).folder, fileName);

        % Read table
        T = readtable(filePath);

        % Push variable into base workspace
        assignin('base', siteName, T);

    end
end