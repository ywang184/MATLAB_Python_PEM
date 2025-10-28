startAngle=71;
endAngle=78;
startFrame=1000;
endFrame=4000;
FrameNum=endFrame-startFrame+1
AngleSweep=linspace(startAngle, endAngle, FrameNum)';
%update the numbers for each set



%% INITIALIZE DATA FROM IMAGES
warning off;
directory_name = uigetdir;
filelist = dir([directory_name,'\','*.tif']);
[N,M] = size(imread([directory_name,'\', filelist(1).name]));
LoadFrame=FrameNum;  %THIS IS NUMBER OF FRAMES TO LOAD (AKA APPROX # CYCLES * FRAMES PER CYCLE) 
Images = zeros(N,M,LoadFrame,'single');
StartFM = startFrame; %IMAGEJ AVERAGE FIRST FRAME

%load images and smooth 5X5 pixels
a = waitbar(0, 'Wait for loading images');
for i = StartFM:StartFM+LoadFrame-1
    waitbar((i-StartFM+1)/(LoadFrame),a,'Image Read');
    Images(:,:,i-StartFM+1) = single(imread([directory_name,'\', filelist(i).name]));
end
close(a);


% Get the size of the image stack
[height, width, numFrames] = size(Images);

% Initialize result image
resultImage = zeros(height, width);

% Loop over every pixel
for x = 1:height
    for y = 1:width
        % Extract pixel values over the third dimension
        pixelValues = squeeze(Images(x, y, :));

        % Find the index of the minimum value
        [~, minIndex] = min(pixelValues);

        % Get the corresponding value from AngleSweep
        resultImage(x, y) = AngleSweep(minIndex);
    end
end

% Display the final result as an image plot
figure;
imagesc(resultImage);
colormap(jet); % Use a color map
caxis([75.5 76.5]);
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
borderX = [1, size(resultImage, 2), size(resultImage, 2), 1, 1];
borderY = [1, 1, size(resultImage, 1), size(resultImage, 1), 1];
plot(borderX, borderY, 'k', 'LineWidth', 1.5); % Black border
colorbarHandle.Ticks = linspace(75.5, 76.5, 3);


%run some smoothing 

%smooth on the time domain // remove noise
for i = 1:size(Images,1)
    for j = 1:size(Images,2)
        % smooth fn matlab - types/parameters
        ImagesS(i,j,:) = smooth(Images(i,j,:),15); %THE FIRST AVERAGE NUMBER
    end
end


%smooth on the space domain
for i = 1:size(ImagesS,3)
    ImagesSS(:,:,i) = filter2(ones(5,5),ImagesS(:,:,i))/25;
end
clear ImagesS;

% Get the size of the image stack
[height, width, numFrames] = size(ImagesSS);

% Initialize result image
resultImage = zeros(height, width);

% Loop over every pixel
for x = 1:height
    for y = 1:width
        % Extract pixel values over the third dimension
        pixelValues = squeeze(ImagesSS(x, y, :));

        % Find the index of the minimum value
        [~, minIndex] = min(pixelValues);

        % Get the corresponding value from AngleSweep
        resultImage(x, y) = AngleSweep(minIndex);
    end
end

figure;
imagesc(resultImage);
colormap(jet); % Use a color map
caxis([75.5 76.5]);
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
borderX = [1, size(resultImage, 2), size(resultImage, 2), 1, 1];
borderY = [1, 1, size(resultImage, 1), size(resultImage, 1), 1];
plot(borderX, borderY, 'k', 'LineWidth', 1.5); % Black border
colorbarHandle.Ticks = linspace(75.5, 76.5, 3);


% Add a properly positioned scale bar (50 µm)
%scaleBarLength = 50; % Scale bar length in micrometers
%pixelsPerMicron = 1; % Since each pixel = 1 µm
%xStart = size(resultImage, 2) - scaleBarLength * pixelsPerMicron - 40; % X position (right bottom)
%yStart = size(resultImage, 1) - 20; % Y position (slightly above the border to avoid overlap)

% Draw scale bar
%plot([xStart, xStart + scaleBarLength * pixelsPerMicron], [yStart, yStart], 'k', 'LineWidth', 4);

% Move the scale bar label higher to avoid overlap
%text(xStart + scaleBarLength * pixelsPerMicron / 2, yStart - 40, '50 µm', ... % Increased Y-offset
 %   'FontSize', 12, 'HorizontalAlignment', 'center', 'Color', 'k', 'FontWeight', 'bold');

%hold off;

%colorbarHandle.Ticks = linspace(min(resultImage(:)), max(resultImage(:)), 5); % Adjust tick positions
%colorbarHandle.TickLabels = compose('%.1f', colorbarHandle.Ticks); % Format to 1 decimal place