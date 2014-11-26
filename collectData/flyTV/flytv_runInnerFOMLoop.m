function timingList=runInnerFOMLoop(dpy,stim)
% function timinglist=runInnerFOMLoop(dpy,stim)
% The inner loop that runs the first order motion stimulus. It's different
% to the loop that runs the som stim
% stim must contain textures for the two components
% ARW 103114

Screen('BlendFunction', dpy.win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);


% Wait for release of all keys on keyboard, then sync us to retrace:

dpy.vbl = Screen('Flip', dpy.win);
stim.vblStart=dpy.vbl;


% We run at most 'movieDurationSecs' seconds if user doesn't abort via keypress.
vblendtime = dpy.vbl + stim.temporal.duration;
i=1;
maxNFrames=size(stim.thisPhase,1);

phaseInit=stim.spatial.phase; % This is the starting phase of both gratings (a vector)
try
    while (dpy.vbl < vblendtime)
        
        thisFrame=(round((dpy.vbl-stim.vblStart)*dpy.frameRate))+1;
        
        if(thisFrame>maxNFrames)
            thisFrame=maxNFrames;
        end
        
        % Increment phase by the appropriate amount for this time period:
        phase = stim.thisPhase(thisFrame,:)*(180/pi);
       %disp(phase);
        
        % Draw the grating, centered on the screen, with given rotation 'angle',
        % sine grating 'phase' shift and amplitude, rotating via set
        % 'rotateMode'. Note that we pad the last argument with a 4th
        % component, which is 0. This is required, as this argument must be a
        % vector with a number of components that is an integral multiple of 4,
        % i.e. in our case it must have 4 components:
        
        Screen('DrawTexture', dpy.win, [stim.texture{1}], [], [], [stim.spatial.angle(1)], [], [0], [], [], [stim.rotateMode], [phase(1),stim.spatial.frequencyCPerPixel(1),stim.amps(1),0]');
        Screen('DrawTexture', dpy.win, [stim.texture{2}], [], [], [stim.spatial.angle(2)], [], [0], [], [], [stim.rotateMode], [phase(2),stim.spatial.frequencyCPerPixel(2),stim.amps(2),0]');
        
        % Show it at next retrace:
        dpy.vbl = Screen('Flip', dpy.win, dpy.vbl + 0.5 * dpy.ifi);
        timingList(i)=dpy.vbl;
        i=i+1;
    end
catch RENDERINGERROR
    sprintf('\nError in %s',mfilename);
    disp('Rendering error in display loop');
    sca
    rethrow(RENDERINGERROR);
end
