% Code to simulate sampling of a visual scene
% Sample with a hexagonal array of 16x16 receptors
% This is about 2/3 of a fly's eye in each direction (which covers something like 110 degs)
% So roughly we are simulating a square fov that is 110 *2/3 = 73 degrees
% of visual angle each way
% ARW 01/12/14 Wrote it - in github for flytv


close all;
clear all;
load clown; % You can load in an image . Or make a grating yourself.
X1=linspace(0,2*pi*20,256); % A .22 cpd grating has about 16 cycles in this FOV
[xx,yy]=meshgrid(X1);
i1=sin(xx);

% i1=X % This will use the clown image rather than the grating.

[simImage,sampPoints,origImage]=flyTV_imageSim(i1); % Call the simulation function



figure(2);

% Do some plotting
subplot(3,1,1);
hold off;

imagesc(origImage); % Original image
axis image;
axis off;
hold on;

subplot(3,1,2);
% Sampling
h0=scatter(sampPoints.rX,sampPoints.rY,35,sampPoints.cols);

set(h0,'MarkerFaceColor','flat');
set(h0,'MarkerEdgeColor',[0 0 0]);
whitebg([0 0 0]);

%set(h0,'LineWidth',1);
hold off;
colormap gray

axis image;
axis off;
% Now sample this using griddata

subplot(3,1,3);
% Sampled image
colormap gray;


imagesc(simImage);
axis image;
axis off;
return
