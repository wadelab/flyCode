function dataOut=flytv_runGrating(dpy,cyclespersecond, sfreq)  
% Function dataOut=flytv_runGrating(cyclespersecond, sfreq)  
% Acquires 10s of flicker data at
% Data will be acquired from hardware channel 0
% We have to use the new session based interface in WL 2013
% 

global gl; % We make this a global variable so that it can be seen from the listener
gl=[];

s = daq.createSession('ni');
s.DurationInSeconds = 10;
addAnalogInputChannel(s,'Dev3','ai0','Voltage')
s.NumberOfScans = 11000;
s.NotifyWhenDataAvailableExceeds = s.NumberOfScans;
myData=[];

lh = addlistener(s,'DataAvailable', @flytv_dumpData);

% Here we run the flickering grating...
WhichScreen = 1
Screen('Preference', 'SkipSyncTests', 1);
% Open a fullscreen onscreen window on that display, choose a background
% color of 128 = gray, i.e. 50% max intensity:
win.id = Screen('OpenWindow', WhichScreen, 128);
win.ifi=Screen('GetFlipInterval', win.id);
win.vbl = Screen('Flip', win.id);
% Build a procedural sine grating texture for a grating with a support of
% res(1) x res(2) pixels and a RGB color offset of 0.5 -- a 50% gray.
res=[1920 1080]; % cloned screen 1 [3000 800];
win.gratingtex = CreateProceduralSineGrating(win.id, res(1), res(2), [0.5 0.5 0.5 0.0]);

% Make sure the GLSL shading language is supported:
AssertGLSL;

% Wait a little more so the screens are stable

disp('Waiting for screen stability');
pause(2);

% Set the CLUTS to the calibrated values
oldClut = LoadIdentityClut(win.id, 1);
Screen('LoadNormalizedGammaTable',win.id,dpy.gamma.inverse);


angle=0;
%cyclespersecond=5; % Temporal frequency
%sfreq=0.005; % This should be specified in cycles per degree...
gratingsize=3000; % This is in pixels
internalRotation=0; % Does the grating rotate with the envelope? 
duration=10;% How long to flicker for? Note - less than the digitizer acquisition time.


% Begin data acquisition in the background
disp('Running');
startBackground(s);
tic

% Run the stimulus
Flicker5(angle, cyclespersecond, sfreq, gratingsize, internalRotation,duration,win)
toc
%pause(2);
% Here we just wait for a bit...

% We're done. Close the window. This will also release all other ressources:
Screen('CloseAll');

pause(4); % Wait for all the data acq to end
%%
figure(1);
plot(gl.TimeStamps,gl.Data);
figure(2);
fDat=fft(gl.Data(1001:end));
plot(log(abs(fDat(2:450))));
grid on;

% In this case, the height of the 2F1 peak is the one we #want. For 20s of
% acquisition and 5 Hz, this is at 200 cycles / scan
complex2F1=fDat(201);
disp(abs(complex2F1))
disp('Cleaning up');

delete (lh);
delete(s);


dataOut=gl;



