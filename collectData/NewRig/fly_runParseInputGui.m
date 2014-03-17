function [exptStruct,cancelled]=fly_runParseInputGui(exptStruct)
%function exptStruct=fly_runParseInputGui
% Runs the flyGui1 and extracts mission-critical fields. Everything else is
% dumped in exptStruct.b
% Altered 02/24/14 to allow optional exptStruct input - allows GUI to
% recreate state of previously-run experiment
nargin
if (nargin == 0 )
    disp('No inputs');
    origExptStruct=[];
    EXPTSTRUCTPASSED=0;
    [a,b]=flyGui1;
else
    origExptStruct=exptStruct;
    [a,b]=flyGui1(exptStruct.b);
end



nCells=length(b);
% Find values of inputs tagged for wavelength and frequency
for setupF=1:2
    for setupLED=1:4
        exptStruct.F(setupF).LED(setupLED)=0;
    end
end
disp('***********');

fprintf('Parsing GUI data\n');


for thisEntry=1:nCells  % Loop over all the GUI elements, look at the 'tags', extract relevent values
    tagVal=b{thisEntry}.tag;
    % First get the wavelengths
    if (~isempty(tagVal))        
         if(strcmp(tagVal,'nRepeatsList'))
             exptStruct.nRepeats=str2num(b{thisEntry}.string{b{thisEntry}.value});
             
         end
         
        for thisF=1:2
            tagCompare=sprintf('F%.0dFreqList',thisF);
            
            if (strcmp(tagVal,tagCompare))
            %    disp(thisEntry); disp('Freq!!!');
                exptStruct.F(thisF).Freq=str2num(b{thisEntry}.string{b{thisEntry}.value});
            end
            for thisWL=1:4
                tagCompare=sprintf('F%.0dLED%.0d',thisF,thisWL);
                if (strcmp(tagVal,tagCompare))
                    exptStruct.F(thisF).LED(thisWL)=b{thisEntry}.value;
                    %       exptStruct.F(thisF).LEDName(thisWL)=b{thisEntry}.string;
                end % End compare to LED tag
            end  % Next wavelength loop
            if(strcmp(tagVal,'ExperimentTypeList'))
                exptStruct.type=b{thisEntry}.value;
            end
            
        end % Next Freq loop
        
        
        
    end % End check for empty tag
    
    
end % Next entry
%% Lots more stuff can go in the loop above. But for now all we need are frequencies and LEDs to get moving...
a
b

exptStruct.b=b;
cancelled=0; % for now
%%
