function [simImage, simPoints,U]=flyTV_imageSim(inputImage)
%function [simImage, simPoints]=flyTV_imageSim(inputImage)
% Code to simulate sampling of a visual scene
% Sample with a hexagonal array of 16x16 receptors
% This is about 2/3 of a fly's eye in each direction (which covers something like 110 degs)
% So roughly we are simulating a square fov that is 110 *2/3 = 73 degrees
% of visual angle each way


U=imresize(inputImage,[256,256]);
U=U-min(U(:));
U=U./max(U(:));
% Hexagonal grid sampling
% Generate hexagonal grid
Rad3Over2 = sqrt(3) / 2;
pointPlaces=linspace(0,255,16);

[X Y] = meshgrid(pointPlaces);
n = size(X,1);
X = Rad3Over2 * X+8;
Y = Y + repmat([0 8],[n,n/2])+8;

X=X(Y<256);
Y=Y(Y<256);

% % Plot the hexagonal mesh, including cell borders
% [XV YV] = voronoi(X(:),Y(:)); plot(XV,YV,'b-')
% axis equal, axis([10 20 10 20]), zoom on
% hold on;
%scatter(X(:),Y(:),'.');

% Make this as an image so that we can do F-domain filtering

%figure(1);
sampImage=zeros(256,256);
rY=round(Y)+1; rX=round(X)+1;

subPlaces=sub2ind([256 256],rY,rX);
sampImage(subPlaces)=1;

%imagesc(sampImage);
%axis off;
%figure(2);
%subplot(3,1,1);


% Do the filtering
% First on a sinewave grating
X1=linspace(0,2*pi*40,256); % A .22 cpd grating has about 16 cycles in this FOV
[xx,yy]=meshgrid(X1);
%i1=sin(xx);
i1=U;

%subplot(3,1,1);
%hold off;
% 
% imagesc(i1);
% axis image;
% axis off;
% hold on;
cols=repmat((i1(subPlaces)+1)/2,1,3);
%subplot(3,1,2);
simPoints.rX=rX;
simPoints.rY=256-rY; % So that you can plot this with scatter...
simPoints.cols=cols;

%h0=scatter(rX,256-rY,35,cols);

% set(h0,'MarkerFaceColor','flat');
% set(h0,'MarkerEdgeColor',[0 0 0]);
% whitebg([0 0 0]);

%set(h0,'LineWidth',1);
% hold off;
[xx,yy]=meshgrid(linspace(0,255,256));
colormap gray
% 
% axis image;
% axis off;
% Now sample this using griddata
[xq,yq,simImage]=griddata(rX,rY,i1(subPlaces),xx,yy,'nearest');

% subplot(3,1,3);
% colormap gray;
% 
% 
% imagesc(vq);
% axis image;
% axis off;
% return
% 
% fI1=fft2(i1);
% fSamp=fft2(sampImage);
% conIm=fSamp.*fI1;
% sampledRestored=abs(ifft2(conIm));
% 
% subplot(2,1,2);
% imagesc(sampledRestored);
% colormap gray;
% figure(2);
% imagesc(abs(fSamp));


