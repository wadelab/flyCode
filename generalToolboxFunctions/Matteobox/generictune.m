function yy = generictune(pars,xx) 
% GENERICTUNE	sum of two gaussians 
% 
%		syntax is generictune([xtop,ytop,ybot,sigmal,sigmar],xx) 
%
% if you want to know the high cutoff, compute xtop+sigmar*sqrt(log(2))
% if you want to know the low  cutoff, compute xtop-sigmal*sqrt(log(2))
%
% 1997 Matteo Carandini
% part of the Matteobox toolbox

xtop 		= pars(1);
ytop 		= pars(2);
ybot 		= pars(3);
sigmal	= pars(4);
sigmar	= pars(5);

if ytop == ybot
   yy = ytop*ones(size(xx));
   return
end

il 	= find(xx< xtop);
ir 	= find(xx>=xtop);

yy = NaN*xx;

yy(il) = ybot + (ytop-ybot)* exp( -(xx(il)-xtop).^2 / sigmal^2 );
yy(ir) = ybot + (ytop-ybot)* exp( -(xx(ir)-xtop).^2 / sigmar^2 );


