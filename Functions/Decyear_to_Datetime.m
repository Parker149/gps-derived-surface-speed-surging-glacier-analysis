function dt = Decyear_to_Datetime(decimal_year)
    % Convert decimal year(s) to precise datetime using leap-year-aware logic

    year_part = floor(decimal_year);
    fractional_part = decimal_year - year_part;

    % Start and end of each year
    start_of_year = datetime(year_part, 1, 1, 0, 0, 0);
    start_next_year = datetime(year_part + 1, 1, 1, 0, 0, 0);

    % Exact length of year in days (leap year aware)
    year_duration_days = days(start_next_year - start_of_year);

    % Add fractional part in days to get final datetime
    dt = start_of_year + days(fractional_part .* year_duration_days);
end
