function [dataOut]=human_runPlaid(dpy,stim,eegInfo)
% function dataOut=flytv_PlaidDemo2(cyclespersecond, sfreq,contrast)
% Generates a 2-component plaid
% Grating 1 is orthogonal to grating 2
% All the inputs are now 2 element vectors
% that specify the parameters for rgating 1 and grating 2
% So for example
% cyclespersecond=[0.1 0.2]; % The second grating has twice the sf of the
% first one
% Contrast is the contrast of each component. [.5 .5] gives equal
% mixtures of gr 1 and gr 2 with a max screen level of 100%
% You can go higher : so 0.7 .3 is okay
% The conversion from contrast to amplitudes in the code is computed by a
% separate function flytv_computeAlphaAmps
%
% Old comments:
%___________________________________________________________________
%
% Display an animated grating, using the new Screen('DrawTexture') command.
% This demo demonstrates fast drawing of such a grating via use of procedural
% texture mapping. It only works on hardware with support for the GLSL
% shading language, vertex- and fragmentshaders. The demo ends if you press
% any key on the keyboard.
%
% The grating is not encoded into a texture, but instead a little algorithm - a
% procedural texture shader - is executed on the graphics processor (GPU)
% to compute the grating on-the-fly during drawing.
%
% This is very fast and efficient! All parameters of the grating can be
% changed dynamically. For a similar approach wrt. Gabors, check out
% ProceduralGaborDemo. For an extremely fast aproach for drawing many Gabor
% patches at once, check out ProceduralGarboriumDemo. That demo could be
% easily customized to draw many sine gratings by mixing code from that
% demo with setup code from this demo.
%
% Optional Parameters:
% 'angle' = Rotation angle of grating in degrees.
% 'internalRotation' = Shall the rectangular image patch be rotated
% (default), or the grating within the rectangular patch?
% gratingsize = Size of 2D grating patch in pixels.
% freq = Frequency of sine grating in cycles per pixel.
% cyclespersecond = Drift speed in cycles per second.
%

% History:
% 3/1/9  mk   Written.
% 25/04/14 rw531 edited for flytv


%Initialise the ni daq:
if (eegInfo.DORECORDEEG) % The eegInfo field now contains information about whether to record the EEG from the gTec device
    
    try % It's very important that we don't crash and leave the screen in an unusable state -
        % For this device, we use the old-style non session based interface.
        disp('** Initializing amp ***');
        % initialise the amplifier
        h = daqhwinfo(eegInfo.hwName);
        ai = analoginput(eegInfo.hwName,h.InstalledBoardIds{eegInfo.hwIndex});
        disp('** Adding channels');
        addchannel(ai,eegInfo.channels);
        set(ai,'SampleRate',eegInfo.eegsamplerate,'SamplesPerTrigger',eegInfo.eegsamplerate*stim.temporal.duration);
        disp('** Setting buffer mode');
        set(ai,'BufferingMode','Auto');
        % Set the filters
     
        
%         disp('Getting calibration....');
%         [off,scale]=gUSBampCalibration('UB-2014.04.06',true);
%         
%         disp('Saving calibration');
%         gUSBampSaveCalibration(off,scale,'UB-2014.04.06');
%         
%         disp('Getting impedances');
%         imp=gUSBampImpedance('UB-2014.04.06');
%           
        
        disp('**** Setting filters');
        
        for thisChannel=eegInfo.channels
            disp(thisChannel);
            set(ai.Channel(thisChannel),'NotchIndex',eegInfo.notchFilterIndex);
          %  set(ai.Channel(thisChannel),'BPIndex',eegInfo.bandFilterIndex);
        end
        disp(ai)
        dataOut.h=h;
        
%         dataOut.offset=off;
%         dataOut.scale=scale;
%         dataOut.impedence=imp;
%         dataOut.ai=ai;
        
        
    catch AMPINITERROR
        disp('Could not initiate recording hardware');
        dataOut.status=-1;
        dataOut.message='Failed to initialize amp';
        %delete(ai);
        sca;
        
        rethrow(AMPINITERROR);
    end % End try catch on EEG initiation
end % End if initiate amp..


%Now we open the screen
try
    Screen('Preference', 'SkipSyncTests', 1);
    
    % Select Screen
    WhichScreen = dpy.activeScreen;   
    Screen('Preference', 'VisualDebuglevel', 1)% disables welcome and warning screens
    HideCursor % Hides the mouse cursor
    
    % Open a fullscreen onscreen window on that display, choose a background
    % color of 128 = gray, i.e. 50% max intensity:
    win = Screen('OpenWindow', WhichScreen, 128);
    [width, height]=Screen('WindowSize', win);
    % Set the gamma tables.
    % Set the CLUTS to the calibrated values
    oldClut = LoadIdentityClut(win, 1);
    Screen('LoadNormalizedGammaTable',win,dpy.gamma.inverse);
    
    % Make sure the GLSL shading language is supported:
    AssertGLSL;
    pause(.25);
    % Retrieve video redraw interval for later control of our animation timing:
    ifi = Screen('GetFlipInterval', win,10);
    dpy.measuredIFI=ifi;
    
    % AT THIS POINT WE RUN THE STIMULUS MANY TIMES LOOPING OVER CONTRASTS AND
    % MASKS
    
    nRepeats=stim.nRepeats;
    nConds=stim.nConds;
    KbName('UnifyKeyNames');
    
    for thisRun=1:nRepeats  % 5 repeats
        for thisCond=1:nConds
             beep;
            % Check for a 'quit' key (DB 2014)
              [keyIsDown, secs, keyCode] = KbCheck;
            
            if keyCode(KbName('Escape'))
              
             
                sca
                delete(ai);
                error('Escape key pressed');
                % This will return to the desktop
            end
            
            stim.cont=[stim.probeCont(stim.presentOrder(thisRun,thisCond)) stim.maskCont(stim.presentOrder(thisRun,thisCond))];
            % Phase is the phase shift in degrees (0-360 etc.)applied to the sine grating:
            stim.spatial.phase=[0 0 ]; %[rand(1)*360 rand(1)*360];
            stim.spatial.pOffset=rand(2,1)*360;
            
            fprintf('\nRunning %.0d %.0d',stim.cont(1),stim.cont(2));
            
            stim.spatial.frequency=stim.sfList;
            stim.temporal.frequency=stim.tfList;
            
            % Compute increment of phase shift per redraw:
            phaseincrement = [stim.temporal.frequency] * 360 * ifi;
            
            % Build a vector of phases that reverse at the right frequency
            phaseVect1=linspace(0,2*pi*stim.temporal.frequency(1)*stim.temporal.duration,round(stim.temporal.duration*(1/ifi)));
            phaseVect2=linspace(0,2*pi*stim.temporal.frequency(2)*stim.temporal.duration,round(stim.temporal.duration*(1/ifi)));
            phaseVect=[phaseVect1;phaseVect2];
            phaseVect=[phaseVect,zeros(2,100)];
            phaseSign=sign(sin(phaseVect+.001));
            
            % Build a procedural sine grating texture for a grating with a support of
            % res(1) x res(2) pixels and a RGB color offset of 0.5 -- a 50% gray.
            
            % Begin data acquisition in the background
            disp('Running');
            %startBackground(s);
            tic;
            
            
            Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            
            
            % Compute the alpha and amplitudes that we will use
            [amps,alpha]=flytv_computeAlphaAmps(stim.cont);
            
            gratingtex1 = CreateProceduralSineGrating(win, width, height,[.5,.5,.5, 1],400); % Bottom grating
            gratingtex2 = CreateProceduralSineGrating(win,  width, height,[.5 .5 .5 alpha],400); % Top grating blend 50%
      
            % Wait for release of all keys on keyboard, then sync us to retrace:
            if (eegInfo.DORECORDEEG)
                start(ai);
            end
            triggerTime=now;
            vbl = Screen('Flip', win);
            
            
            % We run at most 'movieDurationSecs' seconds if user doesn't abort via keypress.
            vblendtime = vbl + stim.temporal.duration;
            i=0;
            % Update some grating animation parameters:
            phase=stim.spatial.phase;
            degToRad=pi/180;
            
            pixelsPerMeter=dpy.res(1)/dpy.size(1);
            metersPerDegree=dpy.distance*tan(degToRad);
            
            pixPerDegree=pixelsPerMeter*metersPerDegree;
            
            stim.spatial.frequencyCPerPixel=stim.spatial.frequency/pixPerDegree;
            
            timeStampIndex=1;
         
            vlbTimeStamp=zeros(dpy.frameRate*stim.temporal.duration+100,1);
            
            rseed=rand(1)*100;
            rPhase=round(rand(1)*360);
        % This is the loop that displays the flickering grating. It runs
        % very fast
        
        
           stimIndex=1;
           rotationOffset=stim.rotations(thisRun,thisCond);
           
            while (vbl < vblendtime)
                
                
                % Increment phase by the appropriate amount for this time period:
                phase = phase + phaseincrement;
                pMod = 90+90*(phaseSign(:,stimIndex));
                
                contMod=round(mod(phase,180)/180);
                % Draw the grating, centered on the screen, with given rotation 'angle',
                % sine grating 'phase' shift and amplitude, rotating via set
                % 'rotateMode'. Note that we pad the last argument with a 4th
                % component, which is 0. This is required, as this argument must be a
                % vector with a number of components that is an integral multiple of 4,
                % i.e. in our case it must have 4 components:
                %Screen('DrawTexture', win, [gratingtex1], [], [], [stim.spatial.angle(1)], [], [0], [], [], [stim.rotateMode], [pMod(1)+rPhase,stim.spatial.frequencyCPerPixel(1),amps(1)*contMod(1),0]');
                
                Screen('DrawTexture', win, [gratingtex1], [], [], [stim.spatial.angle(1)+rotationOffset], [], [0], [], [], [stim.rotateMode], [pMod(1),stim.spatial.frequencyCPerPixel(1),amps(1),0]');
                Screen('DrawTexture', win, [gratingtex2], [], [], [stim.spatial.angle(2)+rotationOffset], [], [0], [], [], [stim.rotateMode], [pMod(2),stim.spatial.frequencyCPerPixel(2),amps(2),0]');
                %Screen('DrawTexture', win, [gratingtex3], [], [], [], [], [0], [], [], [], [1,rseed,0,0]);
                %Screen('DrawTexture', win, [gratingtex3], [], [], [], [], [0], [], [], [], [stim.cont(1)*100,rseed,0,0]);
                
                % Show it at next retrace:
                %[vbl] = Screen('Flip', win, vbl + 0.5 * ifi);
                drawFixation(win,width,height); % Note - you enter the actual screen width and it works out the location of the FP
                
                [vbl,~,~,missedFlag(timeStampIndex),~] = Screen('Flip', win, vbl + 0.5 * ifi);
                vlbTimeStamp(timeStampIndex)=vbl;
                timeStampIndex=timeStampIndex+1; % We log all the info from the flip in case we missed stuff.
                stimIndex=stimIndex+1;
            end
            endTime=now;
            % We're done. Close the window. This will also release all other ressources:
            
            if (eegInfo.DORECORDEEG) % Get the data if we recorded any
                
                
                pause(.25); % Wait for all the data acq to end
                [data,times]=getdata(ai,ai.SamplesAvailable);
                stop(ai);
                flushdata(ai);
                dataOut.stimIndex=stimIndex;  % Make a note of this - its another way of checking for skipped frames
                dataOut.Stim(thisRun,thisCond)=stim;
                dataOut.vblTimeStamps{thisRun,thisCond}=vlbTimeStamp;
                dataOut.vblMissedFlag{thisRun,thisCond}=missedFlag;
                dataOut.dpy=dpy;
                dataOut.Data{thisRun,thisCond}=data;
                dataOut.TimeStamps{thisRun,thisCond}=times;
                dataOut.Message{thisRun,thisCond}='Recorded data';
                dataOut.Status(thisRun,thisCond)=1;
                dataOut.TriggerTime(thisRun,thisCond)=triggerTime;
                dataOut.EndTime(thisRun,thisCond)=endTime;
                
            else
                dataOut.Data{thisRun,thisCond}=[];
                dataOut.message='No data requested';
            end
        end % Next cond
    end % Next repeat
    
    Screen('CloseAll');
    delete(ai);
    
    
catch ME % Here if we failed to initialize the display or something else broke
    sca
    disp('Something broke within the main display loop');
    disp(ME.identifier);
    dataOut.message=ME;
    rethrow(ME)
end

return
end

%--------------------------------------------------------------------------------------------------
function drawFixation(w, width, height)
% From DB 2014
ulx = width/2;
uly = height/2;
coords(:,1) = [ulx uly];

Screen('DrawDots', w, coords, 3, [0 0 0]);

end



