function cm = enhance( cmapname, exponent )
% Enhances or compresses a colormap wrt the middle value
%
% cm = enhance( cmapname, exponent )
% 
% Choose exponent < 1 to enhance, >1 to compress. 
%
% Exampple:
% cm = enhance( 'bone', 0.4 )
%
% 2006-09 Matteo Carandini

% exponent = 0.8;

nrow = 256;
ii = (1:nrow);              % between 1 and nrow
vv = (ii-nrow/2)/(nrow/2);  % between -1 and 1
vv = sign(vv).*abs(vv).^exponent;
ii = ceil( (nrow/2)*vv + nrow/2);
cm = eval(sprintf('%s(%d)',cmapname,nrow));
cm = cm(ii,:);