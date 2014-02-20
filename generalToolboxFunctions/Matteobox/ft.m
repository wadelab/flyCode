function f = ft(response, tf, SAMPLERATE, foo)
% FT Fourier Transform at a given frequency, oibtained with dot product
%
%	ft(response, tf, SAMPLERATE) is the product of response with
%	exp( 2*pi*i*tf/SAMPLERATE ). If tf is zero it returns the mean.
%
%	If response is two-dimensional, ft operates on the columns and
%	returns a row vector.
%
%	tf is expressed in whatever units SAMPLERATE is expressed in 
%	(I usually use Hz). Only the data within an integer number of periods 
%	are considered.
%
%	An obsolete version of this routine used to need 4 parameters.
%
% 1995-1996 Matteo Carandini
% part of the Matteobox toolbox


if nargin == 4, error('Only 3 parameters please. 4 pars is obsolete'); end

nsamples = size(response,1);
duration = nsamples/SAMPLERATE;

if tf == 0
	f = mean(response);
else
	correctnsamples = floor( SAMPLERATE * floor(duration * tf)/tf );
	if correctnsamples == 0, error('Correctnsamples is zero'); end
	expvec = exp(- (1:correctnsamples) *2*pi*i*tf/SAMPLERATE );
	f = (2/correctnsamples) * expvec * response(1:correctnsamples,:);
end

