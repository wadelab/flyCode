function [ hax, ax, cax, xgrid, ygrid, ddd ] = hist2( xx, yy, xrange, yrange, normflag, prctiles)
% HIST2 2-dimensional histogram
%
% hist2( xx, yy )
%
% hist2( xx, yy, [xmin, dx, xmax], [ymin, dy, ymax])
%
% hist2( xx, yy, [xmin, dx, xmax], [ymin, dy, ymax], 'row') or
% hist2( xx, yy, 'row')
% normalizes by row
%
% hist2( xx, yy, [xmin, dx, xmax], [ymin, dy, ymax], 'column') or
% hist2( xx, yy, 'column')
% normalizes by column
%
% hist2( xx, yy, [xmin, dx, xmax], [ymin, dy, ymax], '', pp)
% shows the percentiles. For example, try pp =[10 50 90].
%
% [ hax ax cax] = hist2()
% returns axes
%
% [ hax ax cax xgrid ygrid ddd ] = hist2()
% also returns the matrix ddd and the grid vectors
%
% 2002-10 Matteo Carandini
% 2003-03 MC added the default x and y ranges

if nargin< 6
   prctiles = [];
end

if nargin < 5
   normflag = '';
end

if nargin == 3
   normflag = xrange;
end

if nargin < 4
   xrange = [min(xx), range(xx)/10, max(xx)];
   yrange = [min(yy), range(yy)/10, max(yy)];
end


xmin = xrange(1); dx = xrange(2); xmax = xrange(3);
ymin = yrange(1); dy = yrange(2); ymax = yrange(3);

xgrid = [xmin+dx/2:dx:xmax];
ygrid = [ymin+dy/2:dy:ymax];

nxgrid = length(xgrid);
nygrid = length(ygrid);

ddd = zeros(nxgrid, nygrid);

for ixgrid = 1:nxgrid
   goodxs = (xx >= xgrid(ixgrid)-dx/2) & (xx < xgrid(ixgrid)+dx/2);
   for iygrid = 1:nygrid
      goodys = (yy >= ygrid(iygrid)-dy/2) & (yy < ygrid(iygrid)+dy/2);
      ddd(ixgrid, iygrid) = nnz( goodxs & goodys );
   end
end

switch normflag
   
case ''
   % do nothing
   
case 'row'		%normalize by row
   for iygrid = 1:nygrid
      ddd(:,iygrid) = ddd(:,iygrid) / max(ddd(:,iygrid));
   end
   
case 'column'	% normalize by column:
   for ixgrid = 1:nxgrid
      ddd(ixgrid,:) = ddd(ixgrid,:) / max(ddd(ixgrid,:));
   end
   
otherwise
   
   error('Do not understand');
end

ddd(isnan(ddd)) = 0;
nresample = 64;

[xxx, yyy] = meshgrid(xgrid, ygrid);
[newxxx, newyyy] = meshgrid(...
   linspace(min(xgrid),max(xgrid),nresample), ...
   linspace(min(ygrid), max(ygrid),nresample),'*cubic');

newddd = interp2(xxx, yyy, ddd', newxxx, newyyy); 

iax = gridplot(2,2,2,1);
imagesc((1-newddd));
set(gca,'ydir','normal');
colormap gray
% set(gca,'xtick',1/2+nresample*[0:0.25:1], 'xticklabel', xmin+(xmax-xmin)*[0:0.25:1]);
% set(gca,'ytick',1/2+nresample*[0:0.25:1], 'yticklabel', ymin+(ymax-ymin)*[0:0.25:1]);
set(gca,'xtick',[], 'ytick',[]); axis tight

ax = axes('position',get(iax,'position'));
set(ax,'color','none','xlim',[xmin-eps xmax+eps],'ylim',[ymin-eps ymax+eps]);

foo = subplot(2,2,2);
boo = imagesc((newddd)); % plotting this just for the purpose of having a colorbar
cax = colorbar;
set([ boo foo],'visible','off')

hax(1) = subplot(2,2,1);
n  = hist(xx, xgrid);
bar(xgrid, n, 1)

hax(2) = subplot(2,2,4);
n  = hist(yy, ygrid);
barh(ygrid, n, 1)

set(hax(1),'xlim',[xmin-eps xmax+eps], 'ylim', [ 0 inf ]); % 'xtick',xmin+(xmax-xmin)*[0:0.25:1]);
set(hax(2),'ylim',[ymin-eps ymax+eps], 'xlim', [ 0 inf ]); % 'ytick',ymin+(ymax-ymin)*[0:0.25:1]);

set([ax, iax, hax], 'plotboxaspectratio',[ 1 1 1], 'box', 'off','tickdir','out');


%--------------------------------------

axes(ax); % to set the current axis

for iprctile = 1:length(prctiles)
   
   pct = prctiles(iprctile);
   pp = zeros(nxgrid,1)*NaN;
   for ixgrid = 1:nxgrid
      goodones = find(xx >= xgrid(ixgrid)-dx/2 & xx < xgrid(ixgrid)+dx/2);
      if any(goodones)
         pp(ixgrid) = prctile(yy(goodones),pct);
      end
   end
   hold on
   plot(xgrid, pp, 'r*', 'Markersize', 13)
   
end


