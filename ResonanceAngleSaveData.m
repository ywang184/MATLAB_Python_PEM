startAngle = 71;
endAngle = 78;
startFrame = 145;
endFrame = 887;
FrameNum = endFrame - startFrame + 1;
AngleSweep = linspace(startAngle, endAngle, FrameNum)';

%% INITIALIZE DATA FROM IMAGES
warning off;
directory_name = uigetdir;
filelist = dir([directory_name, '\', '*.tif']);
[N, M] = size(imread([directory_name, '\', filelist(1).name]));
LoadFrame = FrameNum;
Images = zeros(N, M, LoadFrame, 'single');
StartFM = startFrame;

a = waitbar(0, 'Wait for loading images');
for i = StartFM:StartFM + LoadFrame - 1
    waitbar((i - StartFM + 1) / LoadFrame, a, 'Image Read');
    Images(:, :, i - StartFM + 1) = single(imread([directory_name, '\', filelist(i).name]));
end
close(a);

[height, width, numFrames] = size(Images);
resultImage = zeros(height, width);

for x = 1:height
    for y = 1:width
        pixelValues = squeeze(Images(x, y, :));
        [~, minIndex] = min(pixelValues);
        resultImage(x, y) = AngleSweep(minIndex);
    end
end

%% DISPLAY IMAGE
figure;
imagesc(resultImage);
colormap(jet);
caxis([74 78]);
colorbarHandle = colorbar;
set(colorbarHandle, 'FontSize', 12, 'LineWidth', 1.5);
set(gcf, 'color', 'w');
set(gca, 'FontSize', 15, 'LineWidth', 1.5);
title('SPR Resonance Angle');
axis image off;
hold on;
borderX = [1, size(resultImage, 2), size(resultImage, 2), 1, 1];
borderY = [1, 1, size(resultImage, 1), size(resultImage, 1), 1];
plot(borderX, borderY, 'k', 'LineWidth', 1.5);
colorbarHandle.Ticks = linspace(74, 78, 5);

%% FUNCTION 1: Save angle map to Excel
[saveFile, savePath] = uiputfile('angle_map.xlsx', 'Save Angle Map As');
if saveFile
    writematrix(resultImage, fullfile(savePath, saveFile));
    disp('Angle map saved to Excel.');
end

%% FUNCTION 2: Extract and save line profiles
prompt = {'Enter X (vertical) coordinate for profile:', ...
          'Enter Y (horizontal) coordinate for profile:'};
dlg_title = 'Line Profile Coordinates';
num_lines = 1;
defaultans = {'100', '100'}; % You can change default values
answer = inputdlg(prompt, dlg_title, num_lines, defaultans);

if ~isempty(answer)
    xCoord = str2double(answer{1});
    yCoord = str2double(answer{2});

    if xCoord > 0 && xCoord <= width && yCoord > 0 && yCoord <= height
        verticalProfile = resultImage(:, xCoord);
        horizontalProfile = resultImage(yCoord, :)';

        % Pad the shorter vector with NaNs so both columns have equal length
        maxLen = max(length(verticalProfile), length(horizontalProfile));
        paddedVertical = NaN(maxLen, 1);
        paddedHorizontal = NaN(maxLen, 1);
        paddedVertical(1:length(verticalProfile)) = verticalProfile;
        paddedHorizontal(1:length(horizontalProfile)) = horizontalProfile;

        % Create a table
        lineProfileTable = table((1:maxLen)', paddedVertical, paddedHorizontal, ...
            'VariableNames', {'Index', 'Vertical_Profile', 'Horizontal_Profile'});

        [profileFile, profilePath] = uiputfile('line_profiles.xlsx', 'Save Line Profiles As');
        if profileFile
            writetable(lineProfileTable, fullfile(profilePath, profileFile));
            disp('Line profiles saved to Excel.');
        end
    else
        warning('Coordinates out of bounds. Skipped profile extraction.');
    end
end