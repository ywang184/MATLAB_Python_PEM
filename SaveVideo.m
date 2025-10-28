%Save video
frameRate = 100;
video = VideoWriter('title', 'MPEG-4');
video.FrameRate = frameRate; % Set the frame rate
open(video);

h = figure;
for i = 1:499
    imagesc(ImagesSD(:,:,i), [-100 100]);
    title([num2str(i) 's'], 'fontsize', 20);
    colormap(jet);
    colorbar;
    set(gcf, 'color', 'w');
    axis equal;
    axis tight;
    
    m(i) = getframe(h);
    writeVideo(video, m(i));
end

close(video);
 