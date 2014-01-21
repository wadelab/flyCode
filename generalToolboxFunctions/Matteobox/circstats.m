function [ pref, circvar ] = circstats( yy, oo )
% CIRCSTATS circular statistics
%
% [ pref, circvar ] = circstats( yy, oo ) returns the preferred angle and
% the circular variance of data yy with angles oo. yy can be a tensor with
% dimensions [no, nx, ny], where no is the length of oo. oo is assumed in
% radians, between 0 and pi.
%
% 2004-11 Matteo Carandini

    
nstim   = size(yy,1);
nx      = size(yy,2);

if ndims(yy) == 3
    ny      = size(yy,3);
else
    ny = 1;
end

if length(unique(oo))<3
    disp('Cannot do circular statistics with less than 3 angles');
    pref 	    = zeros(nx, ny);
    circvar 	= zeros(nx, ny);
    return
end

if ny==1
    pp = exp(i*oo(:)); % in orientation code: *2
    mm = sum( yy(:).*pp )./ sum( yy(:) );
    % now orientations in [0 pi] have been stretched onto [0 2*pi]
else
    pp = repmat( exp(i*oo(:)), [ 1, nx, ny ] ); % in orientation code: *2
    mm = squeeze(sum( yy.*pp, 1 ))./ squeeze(sum( yy, 1 ));
end


mm(find(isnan(mm))) = 0;

pref    = angle(mm); 
circvar = 1 - abs(mm);  

% % in optical imaging code:
% pref = angle(mm)+pi; % now from 0 to 2*pi
% pref = pref/2 - pi/2; % finally, bet -pi/2 and pi/2

 
return 

%-------------------------------------------------------
%           code to test the function
%-------------------------------------------------------

oo = 2* pi* [0 1/4 1/2 3/4 ]';

yy = [ 0 10 20 10 ];
yy = [ 10 10 10 10 ];
yy = [ 0 10 0 0 ];
[ pref, circvar ] = circstats( yy, oo );

% figure; plot(oo,yy);

nx = 3;
ny = 4;
yy = zeros(4,nx,ny);
for ix = 1:nx
    for iy = 1:ny
        yy(:,ix,iy) = [ 0 10 0 0 ];
    end
end
[ pref, circvar ] = circstats( yy, oo );

