function t= myetime(t1,t0)
% MYETIME elapsed time in seconds, ignoring days, months and years
%
% 	t = myetime(t1,t0), where t1 and t0 are in the format output by 
%  the function CLOCK.
%
%	it assumes that there is less than one day between t0 and t1
%
% 1997 Matteo Carandini
% part of the Matteobox toolbox

if length(t1)~= 6 | length(t0)~=6
   error('Times must be in format output by CLOCK');
end

s1 = t1(6) + 60*t1(5) + 3600*t1(4);
s0 = t0(6) + 60*t0(5) + 3600*t0(4);

t = s1-s0;

if t<0, t= t+86400; end


   