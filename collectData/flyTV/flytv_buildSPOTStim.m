function stim=flytv_buildSPOTStim(dpy,stim)
% function stim=flytv_buildSPOTStim(dpy,stim)
% Builds a set of textures and matrices for a moving spot stimulus
% We want a set of coherently driftng largeish spots - stimulus parameters
% are things like radius, velocity
% ARW 10/04/19
% % 
% stim(103).stimulusType='SPOT'; 
% stim(103).temporal.frequency=[6 0]; % This is in Hz. There are two frequencies so you could, in theory, have two spot populations on the screen at the same time.
% stim(103).spatial.frequency=[.04,.44]; % Spots are hard-edged circles (the whole point really is that they are broadband). And because we can't use the sine wave display code, we just abandon this sf stuff
% stim(103).spatial.radius=[.5 .5]; % These are the radii of the circles
% in degrees

% stim(103).temporal.velocity=[1 0;0 0] % These are column vectors for the two components. If we make this a RDK at some point, we can use these for the signal dots.
% 
% stim(103).spatial.nComponents=size(stim(103).spatial.frequency,1);
% stim(103).temporal.modulation.type='drift'; % Dots drift around rather than something else (?). I guess we could frequency tag the dots as well?
% stim(103).temporal.modulation.stopStart=0; % 0 is constant drift direction, 1  is reversing
% stim(103).temporal.modulation.frequency=[0 0]; % This is the alternation frequency for stimuli that reverse. This stimulus (103) is an adaptor so it doesn't switch
% 
% stim(103).temporal.duration=30; % Adaptation period
% stim(103).contrast=[40 0]; % Percent. This is relative to a mean gray background- so it can be positive or negative (dark or bright)

               
% Compute some useful calibration parameters
radPerDegree=pi/180; % Radians per degree    
radiansPerScreen=atan(dpy.size(1)/(2*dpy.distance))*2;
degreesPerScreen=radiansPerScreen/radPerDegree;
pixelsPerMeter=dpy.res(1)/dpy.size(1); % Pixels per horizontal screen meter. Should be somethign like 4000
pixPerDegree=dpy.res(1)/degreesPerScreen;
stim.spatial.radiusInPixels=stim.spatial.radius*pixPerDegree;
pixelsPerScreen=dpy.res(1);
    
% Compute the alpha and amplitudes that we will use
[amps,alpha]=flytv_computeAlphaAmps(stim.contrast/100); % This was here when we had overlapping gratings and were interested in intermodulation. It's sort of redundant now.
    
% Make a texture that defines the dots.
[xx yy]=meshgrid((-stim.spatial.stim.spatial.radiusInPixels):(stim.spatial.stim.spatial.radiusInPixels),(-stim.spatial.stim.spatial.radiusInPixels):(stim.spatial.stim.spatial.radiusInPixels));

diskMap=(xx.^2+yy.^2)<(stim.spatial.radiusInPixels.^2)*stim.contrast(1);

disText=Screen('MakeTexture', win, m, [], [], 2);
texrect = Screen('Rect', disText);
inrect = repmat(texrect', 1, stim.spatial.nDots(1));

    
    
    
    

    
    stim.texture{1}=Screen('MakeTexture',dpy.win,gabortex,[],[],[]);
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
    fprintf('\nFrames per duration %d',framesPerDuration);
    
    switch stim.temporal.modulation.stopStart
        case 0
            % This is a continuously moving thing in one direction:             
            stim.thisPhase=rem( stim.thisPhase,2*pi);
        case 1
            % This stops and starts : a sawtooth with gaps
            error('Stop start not implemented yet');
        case 2 % ?
                 % In this case we make a sawtooth based on
            % temporal.modulation.frequency. Then we scale this by the
            % values in stim.thisPhase.. 
            
            stim.stPhase(:,1)=linspace(0,2*pi*stim.temporal.modulation.frequency(1)*stim.temporal.duration,framesPerDuration);
            stim.stPhase(:,2)=linspace(0,2*pi*stim.temporal.modulation.frequency(2)*stim.temporal.duration,framesPerDuration);

            stim.stPhase(:,1)=sawtooth( stim.stPhase(:,1),.5);
            stim.stPhase(:,2)=sawtooth( stim.stPhase(:,2),.5);
            
             % Now scale this.... The value to scale by is how far
            % (in phase) the grating moves in a single period of
            % stim.temporal.modulation
            % : stim.temporal.frequency*2*pi/(stim.temporal.modulation)
            stim.thisPhase(:,1)=stim.stPhase(:,1).*(stim.temporal.frequency(1)*2*pi./stim.temporal.modulation.frequency(1));
            stim.thisPhase(:,2)=stim.stPhase(:,2).*(stim.temporal.frequency(2)*2*pi./stim.temporal.modulation.frequency(2)); 
             
    end