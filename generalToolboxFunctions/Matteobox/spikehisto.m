function [ histos, ts ] = spikehisto(spikesbycycle,samplerate,nbins)
% spikehisto computes cycle histograms of spikes.
% 
%	[ histos, ts ] = spikehisto(spikesbycycle,samplerate,nbins)
%		samplerate is in Hz
%		spikesbycycle is a list of matrices of spikes 
% 		(zeros with numbers where the spikes are, sparse or full) 
%		organized by cycle: each column is a cycle; each row is a sample
%		nbins defaults to 10. 
%
%		The outputs are histos, in spikes/s, and ts, in s
%
% 1995-1996-1997 Matteo Carandini
% part of the Matteobox toolbox



if nargin < 3, nbins = 10; end

if isempty(spikesbycycle)
   error('Input variable spikesbycycle is empty') 
end

if ~iscell(spikesbycycle),
   spikesbycycle = { spikesbycycle };
end

nstimuli = length(spikesbycycle);
histos 	= zeros( nstimuli, nbins );
ts			= zeros( nstimuli, nbins );

ncycles	= zeros(nstimuli,1);
periods	= zeros(nstimuli,1);

for istim = 1:nstimuli
   periods(istim) = size(spikesbycycle{istim},1);
   ncycles(istim) = size(spikesbycycle{istim},2);   
	allspikes = sum( spikesbycycle{istim}, 2 );	% collapse across cycles
	for ibin = 1:nbins
	    from = floor((ibin-1)*periods(istim)/nbins)+1;
	    to   = floor(   ibin *periods(istim)/nbins);
       histos(istim,ibin) = sum(allspikes(from:to));
    end
    ts(istim,:) = ((1:nbins)-0.5)*periods(istim)/nbins /samplerate;
end
histos = histos*samplerate*nbins/(periods(istim)*ncycles(istim));

