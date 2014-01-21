function scalebar( cmap_ax, strlabel, varargin )
% SCALEBAR places a colorbar in a designated axis
%
% scalebar( ax, strlabel, 'ylim', [a b], 'ytick', ... )

imgobj = imagesc( linspace(1,0,100)'*ones(1,20), [ 0 1 ] );
set(cmap_ax, 'xtick',[], 'ytick', [],'nextplot','add');

tick_ax = axes('position',get(cmap_ax,'position')); % this is just for the labels
set(tick_ax,'color','none','xtick',[],varargin{:});
ylabel(strlabel);

set([cmap_ax tick_ax],'plotboxaspectratio',[2 10 1]);
set([cmap_ax tick_ax imgobj],'userdata','noscalebar');
