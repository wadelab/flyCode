function cm = deg2cm( dist, deg)
% DEG2CM converts degrees into centimeters
%
% cm = deg2cm( dist ) tells you what 1 degree is in cm. Dist is in cm.
%
% cm = deg2cm( dist, deg ) lets you specity how many degrees (default: 1)
%
% SEE ALSO: cm2deg

if nargin<1
    error('syntax is cm = deg2cm( dist, deg)');
end

if nargin<2, deg = 1; end

cm = dist*tan(deg*(pi/180));

% deg = atan(cm/dist)/(pi/180)