function [myfiles] = walk_a_directory_recursively(d, pattern)
%% modified after http://rosettacode.org/wiki/Walk_a_directory/Recursively#MATLAB_.2F_Octave

    myfiles = {};
	f = dir(fullfile(d,pattern));
	for k = 1:length(f)
		strNN = sprintf('%s\n',fullfile(d,f(k).name))
        myfiles = [myfiles;strNN] ;
	end;
 
	f = dir(d);
	n = find([f.isdir]);	
	for k=n(:)'
		if any(f(k).name~='.') 
			myfiles= [myfiles;walk_a_directory_recursively(fullfile(d,f(k).name), pattern)];
        end
    end
end 