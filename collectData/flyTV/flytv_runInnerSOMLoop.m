function timingList=flytv_runInnerSOMLoop(dpy,stim)
% function timingList=flytv_runInnerSOMLoop(dpy,stim)
% This is the main loop that renders the stimulus on the screen.
% This is a second order stimulus. The carrier is rendered normally. The
% envelope is overlaid using alpha blending and drifted by taking a
% different window from a larger array
% Textures and frame-by-frame motion indices are held are held in stim.textures{} and
% stim.thisPhase
% ARW 103114

i=1;
Screen('Blendfunction', dpy.win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
phase=stim.spatial.phase; % This is the starting phase of both gratings (a vector)
try
    while (dpy.vbl < stim.vblendtime)
        
        thisFrame=(round((dpy.vbl-stim.vblStart)*dpy.frameRate))+1;
        
        % Increment phase by the appropriate amount for this time period:
        phase = stim.thisPhase(thisFrame);
        
        Screen('DrawTexture', dpy.win, stim.texture{1}, [], []);
        
        sModRectX1=round(stim.pixelsPerCycle1*(mod(phase(1),2*pi)/(2*pi)));%
        sModRectX2=sModRectX1+dpy.res(1);%
        
        % This source rectangle is chosen from a different bit of the
        % modulating texture each time so that you see a drifting overlay
        sRect=[sModRectX1,0,sModRectX2,dpy.res(2)];
        
        % Render the appropriate part of the second (modulating) texture
        Screen('DrawTexture', dpy.win, stim.texture{2}, sRect, []);
        
        % Show it at next retrace:
        dpy.vbl = Screen('Flip', dpy.win, dpy.vbl + 0.5 * dpy.ifi);
        timingList(i)=dpy.vbl;
        i=i+1;
    end
catch RENDERINGERROR
    fprintf('\nError in %s',mfilename);
    disp('Rendering error in display loop');
    sca
    rethrow(RENDERINGERROR);
end
