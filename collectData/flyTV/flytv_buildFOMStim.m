function stim=flytv_buildFOMStim(dpy,stim)
% function stim=flytv_buildFOMStim(dpy,stim)
% Builds a set of textures and matrices for a first order motion stimulus
% 
% ARW 103114
          
% Compute the alpha and amplitudes that we will use
% Retrieve video redraw interval for later control of our animation timing:


% Compute increment of phase shift per redraw:
stim.phaseincrement = [stim.temporal.frequency] * 360 * dpy.ifi;
disp(stim.contrast)
[stim.amps,stim.alpha]=flytv_computeAlphaAmps(stim.contrast/100);

stim.texture{1} = CreateProceduralSineGrating(dpy.win, dpy.res(1), dpy.res(2),[.5,.5,.5, 1]); % Bottom grating
stim.texture{2}= CreateProceduralSineGrating(dpy.win, dpy.res(1), dpy.res(2),[.5 .5 .5 stim.alpha]); % Top grating blend 50%

% Update some grating animation parameters:

degToRad=pi/180;
pixelsPerMeter=dpy.res(1)/dpy.size(1);
metersPerDegree=dpy.distance*tan(degToRad);
pixPerDegree=pixelsPerMeter*metersPerDegree;
stim.spatial.frequencyCPerPixel=stim.spatial.frequency/pixPerDegree;

% Compute the phase for each frame. We use this instead of incrementing
% phase on the fly to improve temporal precision and to make it easier to
% do fancy things like motion reverals and stop/start
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
