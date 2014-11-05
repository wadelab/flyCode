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
eegInfo=exit.eegInfo;

dataOut=0;    global gl; % We make this a global variable so that it can be seen from the listener

gl=[]; % Hold the data.



%Initialise the daq if the appropriate flag is set in eegInfo
if (eegInfo.DAQ_PRESENT)
    try
        disp('** Initializing amp ***');
        
        eegInfo.s = daq.createSession(eegInfo.hwName);
        eegInfo.s.DurationInSeconds = stim.temporal.duration;
        addAnalogInputChannel(eegInfo.s,'Dev3','ai0','Voltage');
        eegInfo.s.NumberOfScans = eegInfo.s.DurationInSeconds*1000;
        eegInfo.s.NotifyWhenDataAvailableExceeds = eegInfo.s.NumberOfScans;
        myData=[];
        
        lh = addlistener(eegInfo.s,'DataAvailable', @flytv_dumpData);
    catch AMPINITERROR
        disp('Could not initiate recording hardware');
        dataOut.status=-1;
        dataOut.message='Failed to initialize amp'; % I know this isn't returned at present but it could be later..
        sca;
        
        rethrow(AMPINITERROR);
    end % End try catch for initialization
end % End check on amp present



try
    
    for thisRepeat=1:expt.nRepeats % This is the number of times the entire sequence is repeated
        for thisCond=1:expt.nConds % This is the number of individual conditions in the sequence (e.g. 4 in the adaptation condition + possibly some blanks)
            
            nStims=length(stim);
            % Loop over stims in sequence
            for thisStim=1:nStims
                phaseincrement = [stim(thisStim).temporal.frequency] * 2*pi * ifi; % How much the gratings increment each step. For flicker, this determines the response frequency
                
   
    
    % Build a procedural sine grating texture for a grating with a support of
    % res(1) x res(2) pixels and a RGB color offset of 0.5 -- a 50% gray.

    % Update some grating animation parameters:
    phase=stim.spatial.phase;
    radPerDegree=pi/180; % Radians per degree
    
    radiansPerScreen=atan(dpy.size(1)/(2*dpy.distance))*2;
    degreesPerScreen=radiansPerScreen/radPerDegree;
    pixelsPerMeter=dpy.res(1)/dpy.size(1); % Pixels per horizontal screen meter. Should be somethign like 4000
    pixPerDegree=dpy.res(1)/degreesPerScreen;
    stim.spatial.frequencyCPerPixel=stim.spatial.frequency/pixPerDegree;
    pixelsPerScreen=dpy.res(1);
    cyclesPerScreen=degreesPerScreen.*stim.spatial.frequency;
    pixelsPerCycle1=pixelsPerScreen(1)./cyclesPerScreen(1); % We need this to generate a larger modulation texture. So that we can crop it in different places to simulate drift.
    
    % Compute the alpha and amplitudes that we will use
    [amps,alpha]=flytv_computeAlphaAmps(stim.cont);
    
    % We have to make our own sine wave grating for the modulator because we
    % only want it to modulate the alpha channel...
    angleList1=linspace(0,2*pi*cyclesPerScreen(1),dpy.res(1)+pixelsPerCycle1*2); %
    [xx_mod,yy_mod]=meshgrid(angleList1,[1:dpy.res(2)]);
    gt1=(((sin(xx_mod))));
    
    
    meanBG=ones([size(gt1,1),size(gt1,2),3])*0;
    fullText=cat(3,meanBG,gt1);
    
    
    angleList2=linspace(0,2*pi*cyclesPerScreen(2),dpy.res(1)); % This resultion also not set correctly
    
    
    [xx_car,yy_car]=meshgrid(angleList2,[1:dpy.res(2)]);
    
    
    
    % Fill the whole onscreen window with a neutral 50% intensity
    % background color and an alpha channel value of 'bgcontrast'.
    % This becomes the clear color. After each Screen('Flip'), the
    % backbuffer will be cleared to this neutral 50% intensity gray
    % and a default 'bgcontrast' background noise contrast level:
    carrText=0; % Initilize this
    gCarr=(sin(xx_car+stim.spatial.pOffset(2)));
    Screen('Blendfunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    % Problem: I don't think we can compute the multiplied gratings in real
    % time. It missed VBLs when we do this, causing the timing to be in
    % error.
    %
    % We want to get going on the SOM stimuli so for now let's just check
    % flicker. We will make two sets of stimuli corresponding to the two
    % flicker conditions and just alternate between them
    transLayer=2;
    lumLayer=1;
    gray=GrayIndex(0);
    
    gt1p1(:,:,lumLayer)=uint8(ones(size(xx_mod))*gray);
    gt1p1(:,:,transLayer)=uint8(((sin(xx_mod)+1)/2)*255);
    
    % gt1p2(:,:,transLayer)=uint8(((sin(xx_mod+pi+stim.spatial.pOffset(1))+1)/2)*255);
    
    % Make two textures
    
    gCarr=uint8(((gCarr+1)/2)*255);
    
    carrierText=Screen('MakeTexture',win,gCarr,[],[],[]);
    
    ModTextP1  = Screen('MakeTexture', win, gt1p1);
    %  ModTextP2  = Screen('MakeTexture', win, gt1p2);
    
    % If the stim.temporal.modulation.stopStart=2
    % then the stim reverses drift direction several times a secondl.
    % This reversal rate is set by  stim.temporal.modulation.reversalRate
    % (e.g. 5)
    
    % We pre-compute the phase vector for all times so that we don't
    % compute it inside the loop.
    % For standard drift, it's just 0....2*pi*cyclesPerSecond*nSeconds (mod
    % 2*pi): In other words a sawtooth
    % For reversal it's a triangle waveform
    % For stop/start it's a triangle wave with gaps in between
    % The matlab command 'sawtooth' is handy here - with the second
    % parameter providing  the option to make a triangle wave
    framesPerDuration=ceil(stim.temporal.duration*dpy.frameRate);
    thisPhase(:,1)=linspace(0,2*pi*stim.temporal.frequency(1)*stim.temporal.duration,framesPerDuration);
    thisPhase(:,2)=linspace(0,2*pi*stim.temporal.frequency(2)*stim.temporal.duration,framesPerDuration);
    
    switch stim.temporal.modulation.stopStart
        case 0
            % This is a continuously moving thing in one direction: A
            % sawtooth
            
            thisPhase=rem(thisPhase,2*pi);
            
            
        case 1
            % This stops and starts : a sawtooth with gaps
            error('Stop start not implemented yet');
        case 2
            % This reverses: A triangle wave (sawtooth(xxxxxx, .5)
            thisPhase(:,1)=sawtooth(thisPhase(:,1),.5)*pi;
            thisPhase(:,2)=sawtooth(thisPhase(:,2),.5)*pi;
            
    end
    
    % Uncomment below to see the phase waveform
    %     figure(1);
    %     plot(thisPhase);
    
    
    % Start data acqisotion, then get ready to enter the loop...
    
    if (DAQ_PRESENT)
        
        % Begin data acquisition in the background
        disp('Running');
        startBackground(s);
        
    end
    vbl = Screen('Flip', win);
    
    
    % We run at most 'movieDurationSecs' seconds if user doesn't abort via keypress.
    vblendtime = vbl + stim.temporal.duration;
    vblStart=vbl;
    
    i=0;
    
    disp('Entering loop');
    
    
    while (vbl < vblendtime)
        
        thisFrame=(round((vbl-vblStart)*dpy.frameRate))+1;
        
        % Increment phase by the appropriate amount for this time period:
        phase = thisPhase(thisFrame);
        
        Screen('DrawTexture', win, carrierText, [], []);
        
        sModRectX1=round(pixelsPerCycle1*(mod(phase(1),2*pi)/(2*pi)));%
        sModRectX2=sModRectX1+dpy.res(1);%
        
        % This source rectangle is chosen from a different bit of the
        % modulating texture each time so that you see a drifting overlay
        sRect=[sModRectX1,0,sModRectX2,dpy.res(2)];
        
        
        % Render the second (modulating) texture
        
        Screen('DrawTexture', win, ModTextP1, sRect, []);
        
        
        
        % Show it at next retrace:
        vbl = Screen('Flip', win, vbl + 0.5 * ifi);
    end
    toc
    % We're done. Close the window. This will also release all other ressources:
    Screen('CloseAll');
    if (DAQ_PRESENT)
        
        pause(1); % Wait for all the data acq to end
        
        % Bye bye!
        dataOut=gl;
    else
        dataOut=-1;
    end
    
catch ME
    
    %le=lasterr;
    % fprintf('\n\n*********\n** ERROR: %s\n',le);
    sca
    ME.rethrow
    disp(ME);
    disp(ME.stack(1));
    
    disp(ME.stack(2));
    %    fprintf('\n\n*********\n** ERROR: %s\n',le);
    ME.rethrow
end


