function analyze_angle_minima_heatmap()
    % --- USER SETTINGS ---
    roiLayout = [12, 8]; % 12 rows, 8 columns = 96 ROIs

    % --- Load Data ---
    [file, path] = uigetfile('*.xlsx', 'Select Excel data file');
    if isequal(file, 0), disp('File selection cancelled'); return; end
    data = readmatrix(fullfile(path, file));

    numROIs = size(data, 2) / 2;
    if mod(numROIs, 1) ~= 0
        error('Expected pairs of columns (angle, intensity) for each ROI.');
    end

    angle_map = zeros(roiLayout);

    for roi = 1:numROIs
        angle_col = data(:, 2*roi - 1);   % All angle columns are the same
        intensity_col = data(:, 2*roi);   % Intensity column for this ROI

        [~, min_idx] = min(intensity_col);
        min_angle = angle_col(min_idx);

        % Map to correct 2D position
        row = ceil(roi / roiLayout(2));
        col = mod(roi-1, roiLayout(2)) + 1;
        angle_map(row, col) = min_angle;
    end

    % --- Plot Heatmap ---
%     figure;
%     imagesc(angle_map);
%     colormap jet;
%     colorbar;
%     title('Angle of Minimum Intensity for Each ROI');
%     xlabel('Column');
%     ylabel('Row');
% Display the final result as an image plot
figure;
imagesc(angle_map);
colormap(jet); % Use a color map
caxis([75 76.5]);
colorbar; % Show color scale
colorbarHandle = colorbar; % Get the colorbar handle
set(colorbarHandle, 'FontSize', 12, 'LineWidth', 1.5); % Make numbers larger and colorbar border thicker
set(gcf,'color','w');
set(gca,'FontSize',15,'LineWidth', 1.5);
title('SPR Resonance Angle');
axis image; % Maintain aspect ratio
%xlabel('Potential/V', 'FontSize', 20); % Set font size for xlabel
%ylabel('dPEM/dt', 'FontSize', 20); % Set font size for ylabel
%remove x and y axis
axis image off;
hold on;
% borderX = [1, size(angle_map, 2), size(angle_map, 2), 1, 1];
% borderY = [1, 1, size(angle_map, 1), size(angle_map, 1), 1];
% plot(borderX, borderY, 'k', 'LineWidth', 1.5); % Black border
colorbarHandle.Ticks = linspace(75, 76.5, 4);
 % --- Save angle map matrix ---
% --- Save angle map matrix and image ---
[~, baseFileName, ~] = fileparts(file);
matFileName = fullfile(path, [baseFileName '_AngleMap.mat']);
tiffFileName = fullfile(path, [baseFileName '_AngleMap.tiff']);

save(matFileName, 'angle_map');
imwrite(uint16(angle_map * 100), tiffFileName); % Save raw values as 16-bit TIFF

disp(['Saved angle map as .mat and .tiff at: ' path]);
end


