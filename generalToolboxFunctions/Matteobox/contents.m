% Matteobox Toolbox.
% Version of 22-February-2002
% amended 28 November 2003
% amended 30 November 2004
%
% Matteo Carandini's utilities toolbox for Matlab
%
% Started in 1995
%
% GRAPHICS
% scalebar      places a well-behaved colormap in the axis you designate
% gridplot      a smarter version of subplot, especially in Matlab 7
% mergefigs      merges two or more figures
% alphabet       useful for labeling axes
% circle         draws a circle
% errstar        plots a series of points with error bars in both x and y
% fillplot       fills the area between two plots
% supertitle     makes a big title over all subplots
% moveax         changes the position of a list of axes
% matchy         fixes the y scale of a list of axes
% changeunits    expresses axes dims in different units
% disptune       displays experimental data and a tuning curve
% islogspaced	 tries to see if a vector is more linearly spaced or log spaced...
% lognums	     useful numbers for logplots
% sidetitle      places a title on the right side of an axes object
%
% TWO DIMENSIONAL HISTOGRAMS
% hist2				2-dimensional histogram
% 
% VISUAL STIMULI
% plaidimage		draws a plaid or a grating, useful for talks, papers, posters...
%
% TO FIND SPIKES AND WORK WITH THEM
% findspikes      finds the spikes in membrane potential traces
% spikehisto      computes cycle histograms of spikes
% ftspikes        Fourier Transform of full/sparse data at a given frequency
%
% FOR PSYCHOPHYSICS
% psycho 			the erf function with two parameters
% rvc 				psychophysical contrast response function R = k c^(m+n)/[sigma^m + c^m]
% tvc					threshold vs. contrast function based on rvc
%
% FITTING FUNCTIUONS
% fitit         least squares fitting of a model (based on 'fmins')
% lsqfit        least squares fitting of a model (using 'lsqcurvefit')
%	
% TO FIT DATA
% generictune     sum of two gaussians that meet at the peak, eg to fit frequency tuning
% fitgeneric      fits generictune to the data
% oritune         sum of two gaussians that live on a circle, eg to fit orientation tuning
% fitori          fits oritune to the data
% hyper_ratio     hyperbolic ratio function, eg to fit contrast responses
% fit_hyper_ratio fits hyper_ratio to the data
% expfunc         an exponential decay function
% gaussian        a gaussian
%
% STATISTICS
% circstats      circular statistics (circular variance, preferred angle)
%
% FOR CROSS-PLATFORM ISSUES
% grep           finds the files that contain a certain string
% mac2pc         fixes the end-of-line problem when going from the Mac to the PC
%
% MISCELLANEOUS
% myetime         elapsed time in seconds, ignoring days, months and years
% degdiff 			difference in degrees between two angles
% findmax			finds the position of the maximum in a vector
%   MakeBestSeparableModel - [BestRow,BestCol,BestScl,BestModel,Residual] = MakeBestSeparableModel(MatrixIn,ShowGraphics);
%   MakeSeparable          - MakeSeparable finds the best separable approximation to a matrix
%   RaisedCosWin           - RaisedCosWin a raised cosine window useful for filtering
%   alphabet               - useful for labels
%   changeunits            - expresses axes dims in different units
