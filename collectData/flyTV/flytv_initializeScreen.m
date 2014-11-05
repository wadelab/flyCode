function dpy=fly_initializeScreen(dpy)
% function dpy=fly_initializeScreen(dpy)
% Initializes the screen based on info in the dpy structure.
% Clears the screen and returns gracefully if there's a problem
% ARW 102414 - Wrote it.

try % Initialize the screen.
    % This now happens in the main loop and the
    % initialized screen params get sent into the stim display function
    
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
    Screen('Preference', 'VisualDebuglevel', dpy.VisualDebugLevel);% disables welcome and warning screens
    Screen('Preference', 'SkipSyncTests', dpy.SkipSyncTests);
    Screen('Preference', 'SuppressAllWarnings', dpy.SuppressAllWarnings);
    % Select Screen
    WhichScreen = dpy.defaultScreen;
    
    
    HideCursor; % Hides the mouse cursor
    
    % Open a fullscreen onscreen window on that display, choose a background
    % color of 128 = gray, i.e. 50% max intensity:
    dpy.win = Screen('OpenWindow', WhichScreen, 0);
    
    % Set the gamma tables.
    % Set the CLUTS to the calibrated values
    dpy.oldClut = LoadIdentityClut(win, 1);
    Screen('LoadNormalizedGammaTable',win,dpy.gamma.inverse);
    
    dpy.hz=Screen('FrameRate', win,[],dpy.frameRate);
    
    % Make sure the GLSL shading language is supported:
    % AssertGLSL;
    
    % Retrieve video redraw interval for later control of our animation timing:
    dpy.ifi = Screen('GetFlipInterval', dpy.win);
    
    
    if (round(dpy.ifi*100)~=round(100/dpy.frameRate))
        disp(dpy.ifi);
        disp(100/dpy.frameRate);
        
        error('Framerate incorrect'); % This is within a try catch statement so sca will be done later.
    end
    dpy.status=1;
    
catch SCREENINITERROR
    disp('Could not initialize the screen');
    sca
    rethrow(SCREENINITERROR);
end % End screen initialization error



