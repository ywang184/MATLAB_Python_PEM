%Plot CV
%load the first frame and draw the ROI
figure;
fig = imagesc(ImagesAve(:,:,100));title([num2str(i)]);colormap(jet);colorbar;set(gcf,'color','w');axis equal;
roi = drawpolygon(); %manually draw the ROI (e.g., freehand, polygon)

%create a binary mask from the ROI
roiMask = createMask(roi);

%initiate the signal array to hold the mean intensity for each frame 
signal = zeros(1, size(ImagesAve,3));

%Loop through each frame and extract the signal from the ROI
for i = 1: size(ImagesAve,3)
    %load the current frame
    currentImage = ImagesAve(:,:,i);
%apply roi mask to the current image
    roiPixels = currentImage(roiMask);
    
    %calculate the mean
    signal(i) = mean(roiPixels)/655.36*50;
end 

%plot 
figure;
plot(V(1:500), signal);
xlabel('Potential/V');
ylabel('dPEM');

%select folder to save
folderPath = uigetdir(pwd, 'Select Folder to Save Files');
if folderPath == 0
    disp('User canceled folder selection.');
    return;
end 

%File names
dataFilename = 'region5.xlsx';
figureFilename = 'region5.tiff';

%Full paths
dataFullPath = fullfile(folderPath, dataFilename);
figureFullPath = fullfile(folderPath, figureFilename);

%Save data
writematrix(signal, dataFullPath);
saveas(gcf, figureFullPath, 'tiff');

    