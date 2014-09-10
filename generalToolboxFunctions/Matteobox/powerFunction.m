function f = powerFunction(pars,cs)
% f = powerFunction(pars,cs)
% Returns a power function of the format R = b*C^g

pars=pars(:);

if length(pars(:))~=2
   error('You need to specify 2 parameters');
end

b 	= pars(1);
g = pars(2);

f=b*(cs.^g);


