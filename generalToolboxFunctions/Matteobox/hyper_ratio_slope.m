function df = hyper_ratio_slope_ccc(pars,c)
% SLOPE OF HYPER_RATIO_ccc  modified hyperbolic ratio function
%
%	R = a*x^p / (b + c*x^q)
%	gives f = Rmax* cs.^n./(sigma^n+cs.^n) + R0
%	
% 1995-1998 Matteo Carandini
% 1999 Matteo Carandini, check for zero denominators
% part of the Matteobox toolbox

if length(pars(:))~=4
   error('You need to specify 4 parameters');
end

r 	= pars(1);
s = pars(2);
n 	= pars(3);
R0 	= pars(4); 

%((partial d))/((partial d)c)((R c^n)/(c^n+k^n)) = 
%(R c^n (log(c)
%n'(c)+n/c))/(c^n+k^n)+(c^n R'(c))/(c^n+k^n)-(R c^n (c^n (log(c) n'(c)+n/c)+k^n ((n k'(c))/k+log(k) n'(c))))/(c^n+k^n)^2


% Thanks to Wolfram for the differentiation...
df = (r.*n.*(c.^(n-1)))./(c.^n+s.^n)-...
 (r.*(c.^n).*n.*(c.^(n-1)))./((c.^n+s.^n).^2);

 
