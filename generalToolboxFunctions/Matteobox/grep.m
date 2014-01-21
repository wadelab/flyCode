function a = grep(s,d)
% GREP finds the files that contain a certain string
%
% 	A = grep(S,D) returns A array of names of files in directory
% 	D that contain the string S. Both D and S are strings.
%	D can contain wildcards.
%	
% 1997 Matteo Carandini
% part of the Matteobox toolbox


% d = [ DATADIR '438:438*.p*' ]

if nargin<2
   d = pwd;
end

if ~ischar(s) | ~ischar(d)
	error('Arguments must be strings');
end

dd = dir(d);
dd = dd([dd.isdir] == 0);
disp(['Scanning ' num2str(length(dd)) ' files for the string ' s '...']);

a = {};

for ifile = 1:length(dd)
   thisfile = fullfile( d, dd(ifile).name );
   fp = fopen(thisfile);
	ss = fscanf(fp,'%s');
	if any( findstr(s,ss) )
		a{end+1} = dd(ifile).name;
	end
	fclose(fp);
end

disp('...done');
	
		
	
	
