function dataOut=flytv_PlaidDemo3(cyclespersecond, sfreq, contrast)
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

% Make sure this is running on OpenGL Psychtoolbox:
%AssertOpenGL;

global gl; % We make this a global variable so that it can be seen from the listener
gl=[];

% Get the calibration and compute the gamma table
igt=fly_computeInverseGammaFromCalibFile('CalibrationData_190514.mat')

% Initial stimulus parameters for the grating patch:

    internalRotation = 0; % Does the grating rotate within the envelope?
    rotateMode = []; % rotation of mask grating (1= horizontal, 2= vertical, etc?)
    res = [1920 1080]; % screen resoloution
    sfreq = [8/1000, 8/1000];% Frequency of the grating in cycles per pixel: Here 0.01 cycles per pixel,,This should be specified in cycles per degree...
    cyclespersecond = [2 1]; % temporal frequency
    angle = [0 90]  ; % angle of gratings on screen
    Duration=20; % how long to flicker for
    contrast=[.5 .5]

% Amplitude of the grating in units of absolute display intensity range: A
% setting of 0.5 means that the grating will extend over a range from -0.5
% up to 0.5, i.e., it will cover a total range of 1.0 == 100% of the total
% displayable range. As we select a background color and offset for the
% grating of 0.5 (== 50% nominal intensity == a nice neutral gray), this
% will extend the sinewaves values from 0 = total black in the minima of
% the sine wave up to 1 = maximum white in the maxima. Amplitudes of more
% than 0.5 don't make sense, as parts of the grating would lie outside the
% displayable range for your computers displays:




Screen('Preference', 'SkipSyncTests', 1);

% Select Screen
WhichScreen = 1

Screen('Preference', 'VisualDebuglevel', 1)% disables welcome and warning screens
HideCursor % Hides the mouse cursor


% Open a fullscreen onscreen window on that display, choose a background
% color of 128 = gray, i.e. 50% max intensity:
win = Screen('OpenWindow', WhichScreen, 128);
oldClut = LoadIdentityClut(win, 1);

Screen('LoadNormalizedGammaTable',WhichScreen,igt);

% Make sure the GLSL shading language is supported:
AssertGLSL;

% Retrieve video redraw interval for later control of our animation timing:
ifi = Screen('GetFlipInterval', win);

% Phase is the phase shift in degrees (0-360 etc.)applied to the sine grating:
phase=[0 0];

% Compute increment of phase shift per redraw:
phaseincrement = [cyclespersecond] * 360 * ifi;


% Build a procedural sine grating texture for a grating with a support of
% res(1) x res(2) pixels and a RGB color offset of 0.5 -- a 50% gray.


Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% Compute the alpha and amplitudes that we will use
[amps,alpha]=flytv_computeAlphaAmps(contrast);

gratingtex1 = CreateProceduralSineGrating(win, res(1), res(2),[.5 .5 .5 1]); % Bottom grating
gratingtex2 = CreateProceduralSineGrating(win, res(2), res(1),[.5 .5 .5 alpha]); % Top grating blend 50%

% Wait for release of all keys on keyboard, then sync us to retrace:

vbl = Screen('Flip', win);


% We run at most 'movieDurationSecs' seconds if user doesn't abort via keypress.
 vblendtime = vbl + Duration;
    i=0;

while (vbl < vblendtime)
    
    % Update some grating animation parameters:
    
    % Increment phase by the appropriate amount for this time period:
    phase = phase + phaseincrement;
    pMod = 180*(round(phase/180 ));
        

    
    % Draw the grating, centered on the screen, with given rotation 'angle',
    % sine grating 'phase' shift and amplitude, rotating via set
    % 'rotateMode'. Note that we pad the last argument with a 4th
    % component, which is 0. This is required, as this argument must be a
    % vector with a number of components that is an integral multiple of 4,
    % i.e. in our case it must have 4 components:

     Screen('DrawTexture', win, [gratingtex1], [], [], [angle(1)], [], [0], [], [], [rotateMode], [pMod(1),sfreq(1),amps(1),0]');
     Screen('DrawTexture', win, [gratingtex2], [], [], [angle(2)], [], [0], [], [], [rotateMode], [pMod(2),sfreq(2),amps(2),0]');


    % Show it at next retrace:
    vbl = Screen('Flip', win, vbl + 0.5 * ifi);
end

% We're done. Close the window. This will also release all other ressources:
Screen('CloseAll');

% Bye bye!
dataOut=gl;
