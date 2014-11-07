function [dataOut]=fly_runSOMAdapt(dpy,expt)
% This code does two things:
% Runs a preliminary period of adaptaion (say, 30s) in one direction
% Then a second period of 'probe' (say, 4s) which alternates direction
% Then repeat
% Stimuli can be First order motion (FOM) or second order motion (SOM)
% And we have a 2x2 combination of adapt x probe
% Idea is that 1st harmonics are present after adaptation in the same
% channel
% So we can see if SOM and FOM act independently.
% This code is loosely based on original SOM fly code as well as Tunis code
% (which incorporates a more efficient screen setup)
% dpy should have been initialized with a valid screen before entering this
% code.
% We also initialize the eeg system outside this block eventually. For now
% we leave it here.
% expt contains stim and eegInfo
% stim must be a struct array with at least 1 member
%  Members of stim will be evaluated in turn. stim(1), stim(2) etc...


stim=expt.stim;
eegInfo=expt.eegInfo;

dataOut=0;    global gl; % We make this a global variable so that it can be seen from the listener

gl=[]; % Hold the data.

if (eegInfo.DAQ_PRESENT)
    eegInfo=flytv_initializeDAQ(eegInfo); % Attempt to initialize the EEG/DAQ system
end


try
    dpy.ifi = Screen('GetFlipInterval', dpy.win);
    
    
    for thisRepeat=1:expt.nRepeats % This is the number of times the entire sequence is repeated
        for thisCond=1:expt.nConds % This is the number of individual conditions in the sequence (e.g. 4 in the adaptation condition + possibly some blanks)
            
            nStims=size(expt.stimType,1)
            % Loop over stims in sequence
            for thisStimIndex=1:nStims
                thisStim=stim(expt.stimType(thisStimIndex,thisCond));
                
                phaseincrement = [thisStim.temporal.frequency] * 2*pi * dpy.ifi; % How much the gratings increment each step. For flicker, this determines the response frequency
                
                % We have to work out whether the order of the stim is 1 or
                % 2. These have different generators:
                % 1: is a first order motion stim where the 2nd component
                % is often ignored (although we could have plaids etc) - or
                % else it can be a mask.
                % 2: Is a second order motion stim where the first
                % component is the carrer and the second component is the
                % modulator or envelope.
                
                switch thisStim.stimulusType
                    
                    case 'FOM'
                        [thisStim]=flytv_buildFOMStim(dpy,thisStim); % Build first order motion stim
                    case 'SOM'
                        [thisStim]=flytv_buildSOMStim(dpy,thisStim); % Build second order motion stim
                        
                    otherwise
                        disp('Undefined stimulus');
                        % Nothing
                        
                end
                
                % Start data acqisotion, then get ready to enter the loop...
                if (eegInfo.DAQ_PRESENT && eegInfo.DORECORDEEG)
                    % Begin data acquisition in the background
                    disp('Running');
                    startBackground(s);
                    
                end
                dpy.vbl = Screen('Flip', dpy.win);
                
                
                % We run at most 'movieDurationSecs' seconds if user doesn't abort via keypress.
                thisStim.vblendtime = dpy.vbl + thisStim.temporal.duration;
                thisStim.vblStart=dpy.vbl;
                
                disp('Entering loop');
                
                switch thisStim.stimulusType
                    case 'FOM'
                        timinglist=runInnerFOMLoop(dpy,thisStim); % First order motion
                        
                    case 'SOM'
                        timingList=flytv_runInnerSOMLoop(dpy,thisStim); % Second order motion
                    otherwise
                end % End switch statement
                
                % Collect EEG Data for this stim presentation
                if (eegInfo.DAQ_PRESENT && eegInfo.DORECORDEEG)
                    
                    pause(.1); % Wait for all the data acq to end
                    
                    % Bye bye!
                    dataOut.data{thisCond,thisRepeat,thisStimIndex}=gl;
                    dataOut.stim{thisCond,thisRepeat,thisStimIndex}=thisStim;
                    dataOut.timeStampEnd(thisCond,thisRepeat,thisStimIndex)=now;
                else
                    dataOut.data{thisCond,thisRepeat,thisStimIndex}=-1;
                end
            end % Next stim
        end % Next condition
    end% Next repeat
    
    dataOut.eegInfo=eegInfo;
    dataOut.now=now;
    
    
    Screen('CloseAll');

catch ME
    
    sca
    ME.rethrow
    disp(ME);
    disp(ME.stack(1));
    
    disp(ME.stack(2));
    ME.rethrow
end


