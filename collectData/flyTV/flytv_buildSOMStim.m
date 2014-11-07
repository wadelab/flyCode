function stim=flytv_buildSOMStim(dpy,stim)
% function stim=flytv_buildSOMStim(dpy,stim)
% Builds a set of textures and matrices for a second order motion stimulus
% 
% 
                
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
    cyclesPerScreen=degreesPerScreen.*stim.spatial.frequency; % A vector
    pixelsPerCycle1=pixelsPerScreen(1)./cyclesPerScreen(1); % We need this to generate a larger modulation texture. So that we can crop it in different places to simulate drift.
    
    % Compute the alpha and amplitudes that we will use
    [amps,alpha]=flytv_computeAlphaAmps(stim.cont); % !!!!! EDIT?
    
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
    
    
    % Make two textures
    
    gCarr=uint8(((gCarr+1)/2)*255);
    
    stim.texture{1}=Screen('MakeTexture',dpy.win,gCarr,[],[],[]);
    stim.texture{2}  = Screen('MakeTexture', dpy.win, gt1p1);
    %  ModTextP2  = Screen('MakeTexture', dpy.win, gt1p2);
    
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
    stim.thisPhase(:,1)=linspace(0,2*pi*stim.temporal.frequency(1)*stim.temporal.duration,framesPerDuration);
    stim.thisPhase(:,2)=linspace(0,2*pi*stim.temporal.frequency(2)*stim.temporal.duration,framesPerDuration);
    
    switch stim.temporal.modulation.stopStart
        case 0
            % This is a continuously moving thing in one direction: A
            % sawtooth
            
            stim.thisPhase=rem( stim.thisPhase,2*pi);
            
            
        case 1
            % This stops and starts : a sawtooth with gaps
            error('Stop start not implemented yet');
        case 2
             stim.thisPhase(:,1)=sawtooth( stim.thisPhase(:,1),.5)*pi;
             stim.thisPhase(:,2)=sawtooth( stim.thisPhase(:,2),.5)*pi;
            
    end