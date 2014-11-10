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
