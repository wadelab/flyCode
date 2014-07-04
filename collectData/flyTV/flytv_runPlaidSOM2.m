function [dataOut]=flytv_runPlaid(dpy,stim)
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
DAQ_PRESENT=0;

%Initialise the ni daq:
if (DAQ_PRESENT)
s = daq.createSession('ni');
s.DurationInSeconds = stim.temporal.duration;
addAnalogInputChannel(s,'Dev3','ai0','Voltage')
s.NumberOfScans = s.DurationInSeconds*1000;
s.NotifyWhenDataAvailableExceeds = s.NumberOfScans;
myData=[];

lh = addlistener(s,'DataAvailable', @flytv_dumpData);
end



% Initial stimulus parameters for the grating patch:

% Amplitude of the grating in units of absolute display intensity range: A
% setting of 0.5 means that the grating will extend over a range from -0.5
% up to 0.5, i.e., it will cover a total range of 1.0 == 100% of the total
% displayable range. As we select a background color and offset for the
% grating of 0.5 (== 50% nominal intensity == a nice neutral gray), this
% will extend the sinewaves values from 0 = total black in the minima of
% the sine wave up to 1 = maximum white in the maxima. Amplitudes of more
% than 0.5 don't make sense, as parts of the grating would lie outside the
% displayable range for your computers displays:


%Now we run the Plaid

Screen('Preference', 'SkipSyncTests', 1);

% Select Screen
WhichScreen = 0

Screen('Preference', 'VisualDebuglevel', 1)% disables welcome and warning screens
HideCursor % Hides the mouse cursor

% Open a fullscreen onscreen window on that display, choose a background
% color of 128 = gray, i.e. 50% max intensity:
win = Screen('OpenWindow', WhichScreen, 0);

% Set the gamma tables.
% Set the CLUTS to the calibrated values
oldClut = LoadIdentityClut(win, 1);
Screen('LoadNormalizedGammaTable',win,dpy.gamma.inverse);

hz=Screen('FrameRate', win,[],dpy.frameRate);

% Make sure the GLSL shading language is supported:
% AssertGLSL;

% Retrieve video redraw interval for later control of our animation timing:
ifi = Screen('GetFlipInterval', win);


if (round(ifi*1000)~=round(1000/dpy.frameRate))
    disp(ifi);
    disp(1000/dpy.frameRate);
    sca
    error('Framerate incorrect');
end


% Compute increment of phase shift per redraw:
phaseincrement = [stim.temporal.frequency] * 360 * ifi;


% Build a procedural sine grating texture for a grating with a support of
% res(1) x res(2) pixels and a RGB color offset of 0.5 -- a 50% gray.
if (DAQ_PRESENT)

% Begin data acquisition in the background
disp('Running');
startBackground(s);

end
tic


disp(stim.cont)
toc

% Compute the alpha and amplitudes that we will use
[amps,alpha]=flytv_computeAlphaAmps(stim.cont);
% We have to make our own sine wave grating for the modulator because we
% only want it to modulate the alpha channel...
angleList1=linspace(0,2*pi*10,dpy.res(1));
[xx_mod,yy_mod]=meshgrid(angleList1);
gt1=(((sin(xx_mod))));
meanBG=ones([size(gt1,1),size(gt1,2),3])*0;
fullText=cat(3,meanBG,gt1);

modText  = Screen('MakeTexture', win, fullText, [], [], 1);



angleList2=linspace(0,2*pi*80,dpy.res(1));


[xx_car,yy_car]=meshgrid(angleList2);



%gratingtex1 = CreateProceduralSineGrating(win, dpy.res(1), dpy.res(2),[.5 .5 .5 .5],[],[0 0 0 1]); % Alpha modulator - low SF
%gratingtex2 = CreateProceduralSineGrating(win, dpy.res(1), dpy.res(2),[0 0 0 0]); % Carrier

% Wait for release of all keys on keyboard, then sync us to retrace:

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
    % Fill the whole onscreen window with a neutral 50% intensity
    % background color and an alpha channel value of 'bgcontrast'.
    % This becomes the clear color. After each Screen('Flip'), the
    % backbuffer will be cleared to this neutral 50% intensity gray
    % and a default 'bgcontrast' background noise contrast level:
    
while (vbl < vblendtime)
    
    
    % Increment phase by the appropriate amount for this time period:
    phase = phase + phaseincrement;
    pMod = 180*(round(phase/180 ));
    
    gt1=(sin(xx_mod+phase(2))+1)/2;
    
    %meanBG=ones([size(gt1,1),size(gt1,2),3])*0.5;
    
   % fullText=cat(3,meanBG,gt1);

    %modText  = Screen('MakeTexture', win, fullText, [], [], 1);
    
    % Draw the grating, centered on the screen, with given rotation 'angle',
    % sine grating 'phase' shift and amplitude, rotating via set
    % 'rotateMode'. Note that we pad the last argument with a 4th
    % component, which is 0. This is required, as this argument must be a
    % vector with a number of components that is an integral multiple of 4,
    % i.e. in our case it must have 4 components:
     % Draw the grating, centered on the screen, with given rotation 'angle',
    % sine grating 'phase' shift and amplitude, rotating via set
    % 'rotateMode'. Note that we pad the last argument with a 4th
    % component, which is 0. This is required, as this argument must be a
    % vector with a number of components that is an integral multiple of 4,
    % i.e. in our case it must have 4 components:
      Screen('Blendfunction', win, GL_ONE, GL_ZERO);
        
        % Now we overdraw some regions of the onscreen windows alpha-channel
        % with our "modulation" image - a image that contains alpha values
        % which encode a different contrast 'fgcontrast'. After this drawing op,
        % the alpha-channel will contain the final "contrast modulation landscape":
       % Screen('DrawDots', win, [x y], 50, [0.5 0.5 0.5 fgcontrast], [], 1);


    
    gt2=(sin(xx_car));

    gt2=(gt2.*gt1)/2+.5;
    carrText  = Screen('MakeTexture', win, gt2, [], [], 1);

        % The extra zero at the end forcefully disables bilinear filtering. This is
        % not strictly neccessary on correctly working hardware, but an extra
        % precaution to make sure that the noise values are blitted
        % one-to-one into the offscreen window:
    %Screen('DrawTexture', win, [gratingtex2], [], [], [stim.spatial.angle(2)], [], [0], [], [], [stim.rotateMode], [pMod(2),stim.spatial.frequencyCPerPixel(2),1,0]');
     Screen('DrawTexture', win, carrText, [], [], [], 0);


    
    % This will draw the first (modulating) grating into the display
 
     

    
    % Show it at next retrace:
    vbl = Screen('Flip', win, vbl + 0.5 * ifi);
end

% We're done. Close the window. This will also release all other ressources:
Screen('CloseAll');
if (DAQ_PRESENT)

pause(4); % Wait for all the data acq to end

% Bye bye!
dataOut=gl;
else
    dataOut=-1;
end
