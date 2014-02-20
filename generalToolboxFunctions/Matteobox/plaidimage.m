function img = plaidimage( g, npix )
% PLAIDIMAGE draws a plaid or a grating, useful for talks, papers, posters...
%
% img = plaidimage( g, npix )
% where g can be a vector, and must have the following fields
% c (contrast, bet 0 and 1)
% ori (deg, bet 0 and 180)
% sf (cycles/window)
% phase (deg, bet 0 and 360)
%
% EXAMPLE
% g(1).c = 0.5;
% g(1).ori = 0;
% g(1).sf = 2;
% g(1).phase = 0;
% 
% g(2).c = 0.5;
% g(2).ori = 90;
% g(2).sf = 2;
% g(2).phase = 0;
% 
% npix = 128;
% 
% plaidimage(g,npix);
% print -dtiff 'try.tif'
% 
% 2001 Matteo Carandini
% part of the Matteobox toolbox

ngrats = length(g);

if ~isfield(g,'c') | ~isfield(g,'ori') | ~isfield(g,'sf') | ~isfield(g,'phase')
   error('Need fields c, ori, sf, phase');
end

xx = linspace(-1,1,npix);
yy = linspace(-1,1,npix);

[xxx, yyy] = meshgrid(xx, yy);

ii = zeros(npix,npix);
for igrat = 1:ngrats
	[wx, wy] = pol2cart( g(igrat).ori/180*pi, g(igrat).sf/2 );
	ii = ii + g(igrat).c*sin(2*pi*wx*xxx+2*pi*wy*yyy+pi*g(igrat).phase/180);
end

img = imagesc(xx,yy,ii,[-1 1]);
colormap gray
axis square

return

%------------------- test of the function ---------------------------

g(1).c = 0.5;
g(1).ori = 0;
g(1).sf = 2;
g(1).phase = 0;

g(2).c = 0.5;
g(2).ori = 90;
g(2).sf = 2;
g(2).phase = 0;

npix = 128;

plaidimage(g,npix);
print -dtiff 'try.tif'

%----- to make a bunch of them:
c1s = [0 0.06 0.12 0.25 0.5];
c2s = [0 0.5];

figure; ax = [];
nc1s = length(c1s);
nc2s = length(c2s);
for ic2 = 1:nc2s
for ic1 = 1:nc1s
   g(1).c = c1s(ic1);
   g(2).c = c2s(ic2);
   ax(ic2,ic1) = subplot(nc2s,nc1s,nc1s*(ic2-1)+ic1);
   plaidimage(g,npix);
end
end
set(ax,'xtick',[],'ytick',[],'box','off');
