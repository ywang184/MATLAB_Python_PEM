
[numRows, numCols, numFrames]=size(ImagesAveS);
%initiate a storing matix
maxValues = zeros(numRows, numCols);
minValues = zeros(numRows, numCols);
maxFrameNumbers = zeros(numRows, numCols);
minFrameNumbers = zeros(numRows, numCols);

%initiate images for the final intensity mapping
minImage = zeros(numRows, numCols);
maxImage = zeros(numRows, numCols);

%loop through pixels
for row = 1:numRows
    for col = 1:numCols
        pixelValues = squeeze(ImagesAveS(row, col, 50:450));
        [maxValues(row, col), maxFramenumbers(row,col)] = max(pixelValues);
        [minValues(row, col), minFramenumbers(row,col)] = min(pixelValues);
        
        maxImage(row, col) = V(maxFramenumbers(row,col)+50);
        minImage(row, col) = V(minFramenumbers(row,col)+50);
    end 
end 

figure;
fig = imagesc(maxImage(:,:),[0.35 0.55]);title('reduction peak');colormap(jet);colorbar;set(gcf,'color','w');axis equal;

figure;
fig = imagesc(minImage(:,:),[0.35 0.55]);title('oxidation peak');colormap(jet);colorbar;set(gcf,'color','w');axis equal;

%E1/2
for row = 1:numRows
    for col = 1:numCols
        halfE(row, col) = (maxImage(row, col)+ minImage(row, col))/2;
    end 
end 

figure;
fig = imagesc(halfE(:,:),[0.3,0.6]);title('E1/2');colormap(jet);colorbar;set(gcf,'color','w');axis equal; 


%potential difference
for row = 1:numRows
    for col = 1:numCols
        delatE(row, col) = maxImage(row, col)- minImage(row, col);
    end 
end 
figure;
fig = imagesc(delatE(:,:),[-0.1 0.1]);title('deltaE');colormap(jet);colorbar;set(gcf,'color','w');axis equal;



%plot the images 
figure;for i = 1:size(ImagesSDS,3)
fig = imagesc(ImagesSDS(:,:,i));title([num2str(i)]);colormap(jet);colorbar;set(gcf,'color','w');axis equal;pause(); %RANGE
end
figure;for i = 1:size(ImagesSDS,3)
fig = imagesc(ImagesSDS(:,:,i));title([num2str(V(i)) 'V']);colormap(jet);colorbar;set(gcf,'color','w');axis equal;pause(); %RANGE
end
figure;for i = 1:size(ImagesSDS,3)
fig = imagesc(ImagesSDS(:,:,i),[-15 15]);title([num2str(V(i)) 'V']);colormap(jet);colorbar;set(gcf,'color','w');axis equal;pause(); %RANGE
end

figure;for i = 1:size(ImagesSS,3)/10
imagesc(ImagesSS(:,:,i*10)/65536*100,[-0.2 0.2]);title(num2str(i*10));colormap(jet);colorbar;set(gcf,'color','w');axis equal;pause(); %RANGE
end

%Plot CV
%load the first frame and draw the ROI
figure;
fig = imagesc(SubtractSDS(:,:,150));title([num2str(i)]);colormap(jet);colorbar;set(gcf,'color','w');axis equal;
roi = drawpolygon(); %manually draw the ROI (e.g., freehand, polygon)

%create a binary mask from the ROI
roiMask = createMask(roi);

%initiate the signal array to hold the mean intensity for each frame 
signal = zeros(1, size(SubtractSDS,3));

%Loop through each frame and extract the signal from the ROI
for i = 1: size(SubtractSDS,3)
    %load the current frame
    currentImage = SubtractSDS(:,:,i);
%apply roi mask to the current image
    roiPixels = currentImage(roiMask);
    
    %calculate the mean
    signal(i) = mean(roiPixels);
end 

%plot 
figure;
plot(V(1:499), signal);
xlabel('Potential/V');
ylabel('dPEM');

%LINE PROFILE OVER A FEW PIXELS 

vertical_range = 200:250;
horizontal_range = size(ImagesSDS,2);
for i=1:horizontal_range
    profile(i)=mean(ImagesSDS(vertical_range,i,150));
end 


%Extact peak potentials
%find size
[numRows, numCols, numFrames]=size(ImagesAve);
%initiate a storing matix
maxValues = zeros(numRows, numCols);
minValues = zeros(numRows, numCols);
maxFrameNumbers = zeros(numRows, numCols);
minFrameNumbers = zeros(numRows, numCols);

%initiate images for the final intensity mapping
minImage = zero(numRows, numCols);

%loop through pixels
for row = 1:numRows
    for col = 1:numCols
        pixelValues = squeeze(ImagesAve(row, col, :));
        [maxValues(row, col), maxFramenumbers(row,col)] = max(pixelValues);
        [minValues(row, col), minFramenumbers(row,col)] = max(pixelValues);
        
        maxImage(row, col) = V(maxFramenumbers(row,col));
        minImage(row, col) = V(minFramenumbers(row,col));
    end 
end 

figure;
fig = imagesc(maxImage(:,:));title('reduction peak');colormap(jet);colorbar;set(gcf,'color','w');axis equal;

figure;
fig = imagesc(minImage(:,:));title('oxidation peak');colormap(jet);colorbar;set(gcf,'color','w');axis equal;

%average derived images 
SF=1; %starting frame (should be 1)
CF=500; %cycle frames (THE NUMBER OF FRAMES - IMAGEJ NUMBER OF FRAMES IN A CYCLE)
CN=7;   %cycle number (NUMBER OF CYCLES)
ImagesAve = zeros(N,M,CF,'single');
for i=1:CF
    ImagesSum=zeros(N,M,1,'single');
    for j=1:CN
        ImagesSum(:,:,1)=ImagesSum(:,:,1)+ImagesSDS(:,:,SF+CF*(j-1)+i-1);
    end
    ImagesAve(:,:,i)=ImagesSum(:,:,1)/CN; 
end
