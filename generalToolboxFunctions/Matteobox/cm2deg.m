function deg = cm2deg( dist, cm)
% CM2DEG converts centimeters into degrees
%
% deg = cm2deg( dist ) tells you what 1 cm is in degrees. Dist is in cm.
%
% deg = cm2deg( dist, cm ) lets you specity how many centimeters (default: 1)
%
% SEE ALSO: deg2cm

if nargin<1
    error('syntax is deg = cm2deg( dist, cm)');
end

if nargin<2, cm = 1; end

deg = atan(cm/dist)/(pi/180);