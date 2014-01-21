function plothandle = disptune( xx, yy, ee, style, blankpos, blankstimcolor )
% DISPTUNE utility to display a tuning curve
%
% 		disptune( xx, yy, ee )
%
% 		disptune( xx, yy, ee, style )
%
% 		disptune( xx, yy, ee, style, blankpos) where blankpos is either 
%     a list of stimuli that are blanks (such as [1 6]) or
%     a vector of 0 and 1 the same size as xx (obsolete but still functional)
%
% 		disptune( xx, yy, ee, style, blankpos, blankstimcolor )
%
%		Example:
%
%   xx = [ 1 3 5 2 4 6 ];
%   yy = [ 10 40 80 20 70 10 ];
%   ee = [ 2 3 2 3 2 8  ];
%   blankpos = [1 6];
%   disptune(xx, yy, ee, 'r:o', blankpos )
% 
% 1996 Matteo Carandini
% 2002-05 MC changed list of blanks, can be more than one
%
% part of the Matteobox toolbox

if nargin < 4, style = 'ko-'; end
if nargin < 5, blankpos = []; end
if nargin < 6, blankstimcolor = [.5 .5 .5]; end

xx = xx(:); 
yy = yy(:);

n = length(xx);

if length(yy)~=n, error('xx and yy must have same size'); end

if length(blankpos) == n & all((blankpos == 0)|(blankpos == 1))
   warning('List of blank stimuli with 1 and 0 is obsolete; should be a list of positions');
   blankpos = find(blankpos);
end

if any(blankpos<1|blankpos>n), error('List of blank stimuli is out of bounds'); end

%------------- find the line style, the color, the mark
% useful because:
% 1 - if you don't have a mark style, plot and errorbar will stupidly join the points
% 2 - the blank line must have same color as rest
[ls,col,mark,msg] = colstyle(style); 
if ~isempty(msg), error(msg); end
if isempty(mark), mark = 'o'; end	
style = [ls,col,mark];

holdflag = ishold;

notblank = setdiff(1:length(xx),blankpos);

lx = min(xx(notblank)); rx = max(xx(notblank)); 
% lx = lx - (rx-lx)/18;
% rx = rx + (rx-lx)/18;
if ~isempty(blankpos)
   if ~isnan(blankstimcolor)
      y0 = mean(yy(blankpos));
      e0 = norm(ee(blankpos));
      dy = y0-e0; uy = y0+e0;
      % HACK, to ensure good top limit:
      plot([ lx rx ], 1.2*(uy-dy)+[ uy uy ], 'w', 'visible','off'); hold on
      fill([ lx lx rx rx ],[ dy uy uy dy ],blankstimcolor,'edgecolor','none'); hold on;
   end
   plot([ lx rx ], [ yy(blankpos) yy(blankpos) ], '-','color',blankstimcolor,'linewidth',1); 
end
hold on;

[sortx, perm] = sort(xx(notblank));
sorty = yy(notblank(perm));
sorterr = ee(notblank(perm));

ee = errorbar( sortx, sorty, sorterr, sorterr, col); 
set(ee, 'linestyle','none','marker','none' ); % Was ee(2)
% errorbar( xx(notblank), yy(notblank), ee(notblank), ee(notblank), style ); 

hold on
plothandle = plot( sortx, sorty, style, 'MarkerSize', 8);
% plothandle = plot( xx(notblank), yy(notblank), style, 'MarkerSize', 8);
set(plothandle,'markerfacecolor',get(plothandle,'color'));
set(plothandle,'markeredgecolor',1-get(gca,'defaultlinecolor'));

if ~holdflag, hold off; end

return

%------------------------------------------------------------------------------
%							code to test the function
%------------------------------------------------------------------------------

xx = [ 1 3 5 2 4 6 ];
yy = [ 10 40 80 20 70 10 ];
ee = [ 2 3 2 3 2 8  ];
blankpos = [1 6];

disptune(xx, yy, ee, 'r:o', blankpos )