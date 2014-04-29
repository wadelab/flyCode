function PlaidDemo1(angle, cyclespersecond, sfreq, gratingsize, internalRotation, duration)
% function DriftDemo4([angle=0][, cyclespersecond=1][, freq=1/360][, gratingsize=360][, internalRotation=0])
% ___________________________________________________________________
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

% Make sure this is running on OpenGL Psychtoolbox:
AssertOpenGL;

% Initial stimulus parameters for the grating patch:

    internalRotation = 0; % Does the grating rotate within the envelope?
    rotateMode = []; % rotation of mask grating (1= horizontal, 2= vertical, etc?)
    res = [1920 1080]; % screen resoloution
    sfreq = 1/180;% Frequency of the grating in cycles per pixel: Here 0.01 cycles per pixel,,This should be specified in cycles per degree...
    cyclespersecond = 5; % temporal frequency
    angle = 0  ; % angle of gratings on screen
    Duration=10; % how long to flicker for

% Amplitude of the grating in units of absolute display intensity range: A
% setting of 0.5 means that the grating will extend over a range from -0.5
% up to 0.5, i.e., it will cover a total range of 1.0 == 100% of the total
% displayable range. As we select a background color and offset for the
% grating of 0.5 (== 50% nominal intensity == a nice neutral gray), this
% will extend the sinewaves values from 0 = total black in the minima of
% the sine wave up to 1 = maximum white in the maxima. Amplitudes of more
% than 0.5 don't make sense, as parts of the grating would lie outside the
% displayable range for your computers displays:

amplitude = 0.5;


Screen('Preference', 'SkipSyncTests', 1);

% Select Screen
WhichScreen = 1

Screen('Preference', 'VisualDebuglevel', 1)% disables welcome and warning screens
HideCursor % Hides the mouse cursor

% Open a fullscreen onscreen window on that display, choose a background
% color of 128 = gray, i.e. 50% max intensity:
win = Screen('OpenWindow', WhichScreen, 128);

% Make sure the GLSL shading language is supported:
AssertGLSL;

% Retrieve video redraw interval for later control of our animation timing:
ifi = Screen('GetFlipInterval', win);

% Phase is the phase shift in degrees (0-360 etc.)applied to the sine grating:
phase1 = 0;
phase2 = 0;

% Compute increment of phase shift per redraw:
phaseincrement1 = (cyclespersecond * 360) * ifi;
% Compute increment of phase shift per redraw:
phaseincrement2 = (cyclespersecond * 360 * 2) * ifi; % Twice the frequency
% Build a procedural sine grating texture for a grating with a support of
% res(1) x res(2) pixels and a RGB color offset of 0.5 -- a 50% gray.


Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

gratingtex1 = CreateProceduralSineGrating(win, res(1), res(2),[.5,.5,.5,1]);
gratingtex2 = CreateProceduralSineGrating(win, res(2), res(1),[.5 .5 .5 .5]);

% Wait for release of all keys on keyboard, then sync us to retrace:

vbl = Screen('Flip', win);


% We run at most 'movieDurationSecs' seconds if user doesn't abort via keypress.
 vblendtime = vbl + Duration;
    i=0;

while (vbl < vblendtime)
    
    % Update some grating animation parameters:
    
    % Increment phase by the appropriate amount for this time period:
    phase1 = phase1 + phaseincrement1;
    p2_1 = 180*(round(phase1/180 ));
        
    % Increment phase by the appropriate amount for this time period:
    phase2 = phase2 + phaseincrement2;
    p2_2 = 180*(round(phase2/180 ));
     
    
    % Draw the grating, centered on the screen, with given rotation 'angle',
    % sine grating 'phase' shift and amplitude, rotating via set
    % 'rotateMode'. Note that we pad the last argument with a 4th
    % component, which is 0. This is required, as this argument must be a
    % vector with a number of components that is an integral multiple of 4,
    % i.e. in our case it must have 4 components:

     Screen('DrawTexture', win, [gratingtex1], [], [], [angle], [], [0], [], [], [rotateMode], [p2_1,sfreq,amplitude,0]');
     Screen('DrawTexture', win, [gratingtex2], [], [], [90+angle], [], [0], [], [], [rotateMode], [p2_2,sfreq,amplitude,0]');


    % Show it at next retrace:
    vbl = Screen('Flip', win, vbl + 0.5 * ifi);
end

% We're done. Close the window. This will also release all other ressources:
Screen('CloseAll');

% Bye bye!
return;
