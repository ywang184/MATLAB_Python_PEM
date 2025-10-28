%% 
%% INITIALIZE DATA FROM IMAGES
warning off;
directory_name = uigetdir;
filelist = dir([directory_name,'\','*.tif']);
[N,M] = size(imread([directory_name,'\', filelist(1).name]));
LoadFrame=400;  %THIS IS NUMBER OF FRAMES TO LOAD (AKA APPROX # CYCLES * FRAMES PER CYCLE) 
Images = zeros(N,M,LoadFrame,'single');
StartFM = 1100; %IMAGEJ AVERAGE FIRST FRAME
firstImg = single(imread([directory_name,'\', filelist(StartFM).name]));

%load images
a = waitbar(0, 'Wait for loading images');
for i = StartFM:StartFM+LoadFrame-1
    waitbar((i-StartFM+1)/(LoadFrame),a,'Image Read');
    Images(:,:,i-StartFM+1) = single(imread([directory_name,'\', filelist(i).name]))-firstImg;
end
close(a);



%smooth on the time domain // remove noise
for i = 1:size(Images,1)
    for j = 1:size(Images,2)
        % smooth fn matlab - types/parameters
        ImagesS(i,j,:) = smooth(Images(i,j,:),15); %THE FIRST AVERAGE NUMBER
    end
end
clear Images;


%smooth on the space domain
for i = 1:size(ImagesS,3)
    ImagesSS(:,:,i) = filter2(ones(5,5),ImagesS(:,:,i))/25;
end
clear ImagesS;

% derivative
for i = 1:size(ImagesSS,3)-1
    ImagesSD(:,:,i)=ImagesSS(:,:,i+1)-ImagesSS(:,:,i);
end
%clear ImagesSS;

%smoothing (derivatives)
for i = 1:size(ImagesSD,1)
    for j = 1:size(ImagesSD,2)
        ImagesSDS(i,j,:) = smooth(ImagesSD(i,j,:),15); %THE SECOND AVERAGE NUMBER // final output
    end
end

%plot image sequence 
figure;for i = 1:size(ImagesSDS,3)
fig = imagesc(ImagesSDS(:,:,i)/655.36*50);title([num2str(V(i)) 'V']);colormap(jet);colorbar;set(gcf,'color','w');axis equal;pause(); %RANGE
end
figure;for i = 1:size(ImagesSDS,3)
fig = imagesc(ImagesSDS(:,:,i)/655.36*50, [-2 2]);title([num2str(V(i)) 'V']);colormap(jet);colorbar;set(gcf,'color','w');axis equal;pause(); %RANGE
end

