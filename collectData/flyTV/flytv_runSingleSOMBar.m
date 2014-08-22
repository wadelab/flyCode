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
dataOut=0;
try
    
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
    % ifi is in seconds. So a typical value might be 1/144 = .0069
    
    % Compute increment of phase shift per redraw:
    disp('PI?');
    phaseincrement = [stim.temporal.frequency] * 2*pi * ifi
    disp('s.t.f');
    disp(stim.temporal.frequency);
    disp('ifi');
    disp(ifi);
    
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
    % Update some grating animation parameters:
    phase=stim.spatial.phase;
    degToRad=pi/180;
    
    pixelsPerMeter=dpy.res(1)/dpy.size(1);
    metersPerDegree=dpy.distance*tan(degToRad);
    
    pixPerDegree=pixelsPerMeter*metersPerDegree;
    
    stim.spatial.frequencyCPerPixel=stim.spatial.frequency/pixPerDegree;
    
    pixelsPerScreen=dpy.res(1)
    degreesPerScreen=pixelsPerScreen./pixPerDegree
    
    cyclesPerScreen=degreesPerScreen.*stim.spatial.frequency;
    
    pixelsPerCycle1=pixelsPerScreen(1)./cyclesPerScreen(1); % We need this to generate a larger modulation texture. So that we can crop it in different places to simulate drift.
    
    % Compute the alpha and amplitudes that we will use
    [amps,alpha]=flytv_computeAlphaAmps(stim.cont);
    
    
    % The modulator will be a single gaussian (sine wave?) profile that is
    % swept across the field. Alternatively, we could just compute the
    % strip beforehand using a multiply and sweep it using the srect and
    % drects...
    
    
    
    
    
    % We have to make our own sine wave grating for the modulator because we
    % only want it to modulate the alpha channel...
    angleList1=linspace(0,2*pi*cyclesPerScreen(1),dpy.res(1)+pixelsPerCycle1*2); %
    [xx_mod,yy_mod]=meshgrid(angleList1,[1:dpy.res(2)]);
    gt1=(((sin(xx_mod))));
    
    size(xx_mod)
    
    
    meanBG=ones([size(gt1,1),size(gt1,2),3])*0;
    fullText=cat(3,meanBG,gt1);
    
    %modText  = Screen('MakeTexture', win, fullText, [], [], 1);
    
    angleList2=linspace(0,2*pi*cyclesPerScreen(2),dpy.res(1)); % This resultion also not set correctly
    
    
    [xx_car,yy_car]=meshgrid(angleList2,[1:dpy.res(2)]);
    
    
    % Wait for release of all keys on keyboard, then sync us to retrace:
    
    vbl = Screen('Flip', win);
    
    
    % We run at most 'movieDurationSecs' seconds if user doesn't abort via keypress.
    vblendtime = vbl + stim.temporal.duration;
    i=0;
    
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
    
    while (vbl < vblendtime)
        
        
        % Increment phase by the appropriate amount for this time period:
        phase = phase + phaseincrement;
        
        Screen('DrawTexture', win, carrierText, [], []);
        
        sModRectX1=round(pixelsPerCycle1*(mod(phase(1),2*pi)/(2*pi)));%
        sModRectX2=sModRectX1+dpy.res(1);%
        
        % This source rectangle is chosen from a different bit of the
        % modulating texture each time so that you see a drifting overlay
        sRect=[sModRectX1,0,sModRectX2,dpy.res(2)]
        
        
        % Render the second (modulating) texture
        
        Screen('DrawTexture', win, ModTextP1, sRect, []);
        
  
        
        % Show it at next retrace:
        vbl = Screen('Flip', win, vbl + 0.5 * ifi);
    end
    
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
    
    le=lasterr;
    fprintf('\n\n*********\n** ERROR: %s\n',le);
    sca
    disp(ME);
    disp(ME.stack(1));
    
    disp(ME.stack(2));
    fprintf('\n\n*********\n** ERROR: %s\n',le);
    
end
