function mac2pc(filename, ext)
% MAC2PC fixes the end-of-line characters in a file
%
% On the Macintosh , a "return" at the end of a line is represented by a 
% carriage return (<CR>) only.  On the PC, the "return" at the end of a line is 
% represented by a carriage return, line feed pair (<CR><LF>).  
%
%	mac2pc(filename) opens the file, finds the lonely <CR>s and fixes them.
%
%	mac2pc(dirname) looks for m-file in a directory an dfixes them all
%
%  mac2pc(dirname,'*.EXT') looks for files with extension EXT
%
% 1998 Matteo Carandini
% part of the Matteobox toolbox

if nargin<2
   ext = '*.m';
end

if exist(filename)~=7 & exist(filename)~=2
   error([filename ' is neither a file nor a directory' ]);
end

if exist(filename)==7		% it is a directory
   d = dir(fullfile(filename,ext));
   for ifile = 1:length(d)
      mac2pc(fullfile(filename,d(ifile).name));
   end
   return;
end

ff = fopen(filename);
oldstring = fscanf(ff,'%c',inf);
fclose(ff);

% end of lines must be [13 10];

thirteens 	= find(oldstring==13);
tens 			= find(oldstring==10);

% is there any 10 not preceded by a 13?
badtens = [];
if isempty(thirteens)
   badtens = tens;
else 
   for ten = tens
      if all(thirteens~=ten-1)
         badtens(end+1)=ten;
      end
   end
end

% is there any 13 not followed by a 10?
badthirteens = [];
if isempty(tens)
   badthirteens = thirteens;
else 
   for thirteen = thirteens
      if all(tens~=thirteen+1)
         badthirteens(end+1)=thirteen;
      end
   end
end

disp([ 'File ' filename ': Fixing ' num2str(length(badtens)+length(badthirteens)) ' bad end-of-lines']);

newstring = [];
p0 = 0;
for ten = badtens
   newstring = [ newstring oldstring(p0+1:ten-1) char([13 10]) ];
   p0 = ten;
end
newstring = [ newstring oldstring(p0+1:end) ];

oldstring = newstring;

newstring = [];
p0 = 0;
for thirteen = badthirteens
   newstring = [ newstring oldstring(p0+1:thirteen) char([10]) ];
   p0 = thirteen;
end
newstring = [ newstring oldstring(p0+1:end) ];

ff = fopen(filename,'w');
if ff<=2
   error('File does not appear to be writable');
else
   fprintf(ff,'%c',newstring);
end
fclose(ff);

