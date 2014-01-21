function newfig = mergefigs(figlist,poslist)
% MERGEFIGS merges two or more figures
%
% fig = mergefigs(figlist) creates a new figure fig composed of the figures listed 
% in figlist. Figures are arranged in a row or a column depending on the shape of figlist.
%
% fig = mergefigs(figlist,poslist) lets you specify the positions:
% Poslist has a row [left bottom width height] for each fig.
%
% fig = mergefigs(figarray,'array' ) automatically infers/calculates 
% positions from structure of figarray
%
% EXAMPLE:
% fig1 = figure; plot([ 1 2 3], [4 5 6], 'ro-');
% fig2 = figure; plot([ 1 2 3], [9 7 5], 'go-');
%
% % to put them on top of each other:
% newfig = mergefigs([fig1; fig2]);
% 
% % to put them side by side:
% newfig = mergefigs([fig1, fig2]);
% 
% % to put them side by side, squishing one of them:
% newfig = mergefigs([fig1, fig2], [ 0 0 0.3 1 ; 0.3 0 0.7 1 ]);
% 
% part of the Matteobox toolbox

% 2001-03 Matteo Carandini
% 2002-05 MC made version without "poslist"
% 2002-09 VB calculates positions from input structure if flag 'array'.
% 2002-09 VB objects are now copied in reversed order such that
%            foreground/background relationship preserved.
% 2002-09 VB legend callbacks and scaling now work.
% 2002-09 VB added subroutine to correct inconsistent properties.
%            feel free to add your own axes property to the list below.
% 2003-12 MC implemented arrangement in row or column depending on the shape of figlist 

nfigs = length(figlist);

if nargin<2
    poslist = zeros(nfigs,4);
    for ifig = 1:nfigs
        if size(figlist,1)==1 
            % a row vector
            poslist(ifig,:) = [ (ifig-1)/nfigs 0 1/nfigs 1];
        else
            poslist(ifig,:) = [ 0 1-ifig/nfigs 1 1/nfigs];
        end         
    end
elseif strcmp(poslist,'array')
   [nrows,ncolumns]=size(figlist);
   poslist = zeros(nfigs,4);
   nfigs = nrows*ncolumns;
   for irow = 1:nrows
       for icolumn = 1:ncolumns
           ifig = (icolumn-1)*nrows + irow;
           poslist(ifig,:) = [ (icolumn-1)/ncolumns 1-(irow)/nrows 1/ncolumns 1/nrows];
       end
   end
   figlist = figlist(:);
end

if any(size(poslist)~=[nfigs,4])
   error('Argument poslist should be nfigs X 4');
end

if any(poslist>1)
   error('Positions should be between 0 and 1');
end

for ifig = 1:nfigs
   if ~strcmp( get(figlist(ifig),'type'), 'figure')
      error(['Cannot find a figure number ' num2str(figlist(ifig)) ]);
   end
end

newfig = figure;

for ifig = 1:nfigs
   
   figpos = poslist(ifig,:);
   
   % objects stored in reverse order as a workaround
   % for a bug in copyobj that reverses order before copying
   objs = flipud(get( figlist(ifig), 'children' ));
   
   nobjs = length(objs);
   
   pp = zeros(nobjs,4); % matrix of positions
   for iobj = 1:nobjs
      thisobj = objs(iobj);
      set(thisobj,'units','normalized');
      pp(iobj,:) = get(thisobj,'position');
   end
   
   newobjs = copyobj(objs, newfig ); % duplicate objects
   % check consistency of a set of properties    
   CheckObjectConsistency(figlist(ifig),newfig,objs,newobjs); 
   
   % update positions
   for iobj = 1:nobjs
      thisobj = newobjs(iobj);
      oldpos = pp(iobj,:);
      newpos = oldpos; % just for allocation
      newpos([1 2]) = figpos([1 2])+oldpos([1 2]).*figpos([3 4]); % lower left corner
      newpos([3 4]) = oldpos([3 4]).*figpos([3 4]); % dimensions
      set(thisobj,'position',newpos);
   end
end

return

function CheckObjectConsistency(oldfig,newfig,oldobjs,newobjs);

% list of properties to check for consistency.
% feel free to add your own axes properties to the list below.
% IMPORTANT: property datatype must be supported by 
% the function isequal(x,y)
list = {'XMinorTick','YMinorTick'};

nobjs = length(oldobjs);

for iobj = 1:nobjs
    oldprops = get(oldobjs(iobj));
    newprops = get(newobjs(iobj));
    % check properties consistency
    for item = 1:length(list);
        if isfield(oldprops,list{item}) & isfield(newprops,list{item})
            if ~isequal(getfield(oldprops,list{item}),getfield(newprops,list{item}))
                set(newobjs(iobj),list{item},getfield(oldprops,list{item}));
            end
        end
    end
    % check legend consistency
	if strcmp(get(oldobjs(iobj),'Tag'),'legend') & strcmp(get(newobjs(iobj),'Tag'),'legend')
        if get(oldobjs(iobj),'parent')==oldfig
    		set(newobjs(iobj),'parent',newfig); % set newfig a parent of legend
        end
        ud = get(oldobjs(iobj),'userdata');
        if isfield(ud,'PlotHandle')
            ind = find(oldobjs==ud.PlotHandle);
            ud.PlotHandle = newobjs(ind);
            ud.LegendHandle = newobjs(iobj);
            set(newobjs(iobj),'userdata',ud);
        end
	end
end


return
%---------------- example

fig1 = figure;
subplot(4,1,1); plot([ 1 2 3], [4 5 6], 'ko-');
subplot(2,2,4); plot([ 1 2 3], [9 8 7], 'bs-');
supertitle('figure one');
fig2 = figure;
subplot(3,3,1); plot([ 1 2 3], [4 5 6], 'ro-');
subplot(1,3,2); plot([ 1 2 3], [4 5 6], 'ro-');
subplot(3,3,9); plot([ 1 2 3], [9 8 7], 'gs-');
supertitle('figure two');

figlist = [ fig1, fig2];

poslist = [ 0 0 0.5 1 ; 0.5 0 0.5 1 ];

% 'array' example
f1 = figure;plot([ 1 2 3], [4 5 6], 'ro-');
f2 = figure;plot([ 1 2 3], [4 5 6], 'ko-');
f3 = figure;plot([ 1 2 3], [4 5 6], 'bo-');
f4 = figure;plot([ 1 2 3], [4 5 6], 'go-');
f5 = figure;plot([ 1 2 3], [4 5 6], 'yo-');
f6 = figure;plot([ 1 2 3], [4 5 6], 'mo-');
figarray = [f1 f2 f3; f4 f5 f6];
f = mergefigs(figarray,'array');
close(figarray(:));

% legend example
f1 = figure;plot([ 1 2 3], [4 5 6], 'ro-');
legend('aaa');
f2 = figure;plot([ 1 2 3], [4 5 6], 'ko-');
legend('bbb');
f3 = figure;plot([ 1 2 3], [4 5 6], 'bo-');
legend('ccc');
f4 = figure;plot([ 1 2 3], [4 5 6], 'go-');
legend('ddd');
f5 = figure;plot([ 1 2 3], [4 5 6], 'yo-');
legend('eee');
f6 = figure;plot([ 1 2 3], [4 5 6], 'mo-');
legend('fff');
figarray = [f1 f2 f3; f4 f5 f6];
f = mergefigs(figarray,'array');
close(figarray(:));

% xminortick example
a=[1 10 100];
aa = {'1','10','100'};
b=[4 5 6];
f1 = figure;semilogx(a,b, 'ro-');
set(gca,'xtick',a,'xticklabel',(aa),'xminortick','off');
f2 = figure;semilogx(a,b, 'ko-');
set(gca,'xtick',a,'xticklabel',(aa),'xminortick','off');
f3 = figure;semilogx(a,b, 'bo-');
set(gca,'xtick',a,'xticklabel',(aa),'xminortick','off');
f4 = figure;semilogx(a,b, 'go-');
set(gca,'xtick',a,'xticklabel',(aa),'xminortick','off');
f5 = figure;semilogx(a,b, 'yo-');
set(gca,'xtick',a,'xticklabel',(aa),'xminortick','off');
f6 = figure;semilogx(a,b, 'mo-');
set(gca,'xtick',a,'xticklabel',(aa),'xminortick','off');
figarray = [f1 f2 f3; f4 f5 f6];
f = mergefigs(figarray,'array');
close(figarray(:));
