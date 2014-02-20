function f = lognums
% LOGNUMS useful numbers for logplots
%
% 2001 Matteo Carandini
% part of the Matteobox toolbox

f = [1 2 5]'*10.^[-10:10]; % [0.001 0.01 0.1 1 10 100 1000 10000 100000]

f = f(:);
