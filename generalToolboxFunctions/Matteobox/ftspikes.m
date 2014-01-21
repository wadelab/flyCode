function f = ftspikes(spiketrain, tf, SAMPLERATE,foo)
% FTSPIKES Fourier Transform of full/sparse data at a particular frequency
%
%	ftspikes(spiketrain, tf, SAMPLERATE) is the product of 
%	spiketrain with exp( 2*pi*i*tf/SAMPLERATE ). 
%	I multiply the result by 2 because that's what Victor88 does.
%	If tf is zero it returns the mean.
%
%	If response is two-dimensional, ftspikes operates on the columns and
%	returns a row vector.
%
%	tf is expressed in whatever units SAMPLERATE is expressed in 
%	(I usually use Hz). Only the data within an integer number of periods 
%	are considered.
%
%	An obsolete version of this routine used to need 4 parameters.
%
% 1995, 1996 Matteo Carandini
% part of the Matteobox toolbox

if nargin == 4, error('Only 3 parameters please. 4 pars is obsolete'); end

if tf == 0
	f = full(mean(spiketrain)*SAMPLERATE);
else
	ncols = size(spiketrain,2);
	nsamples = size(spiketrain, 1);
	duration = nsamples/SAMPLERATE;
	f = zeros(1,ncols);
	correctnsamples = floor( SAMPLERATE * floor(duration * tf)/tf );
	if correctnsamples == 0, error('Correctnsamples is zero'); end
	for icol = 1:ncols
		spikesamples = find(spiketrain(1:correctnsamples,icol));
		if isempty(spikesamples)
			f(1,icol) = 0;
		else
			f(1,icol) = 2* sum( full(spiketrain(spikesamples,icol)).*...
						exp(- spikesamples *2*pi*i*tf/SAMPLERATE ) )/...
						(correctnsamples/SAMPLERATE);
		end
	end
end

if any(isnan(f)), error('Result is a NaN'); end
