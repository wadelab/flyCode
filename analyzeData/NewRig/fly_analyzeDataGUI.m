function varargout = fly_analyzeDataGUI(varargin)
% FLY_ANALYZEDATAGUI MATLAB code for fly_analyzeDataGUI.fig
%      FLY_ANALYZEDATAGUI, by itself, creates a new FLY_ANALYZEDATAGUI or raises the existing
%      singleton*.
%
%      H = FLY_ANALYZEDATAGUI returns the handle to a new FLY_ANALYZEDATAGUI or the handle to
%      the existing singleton*.
%
%      FLY_ANALYZEDATAGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FLY_ANALYZEDATAGUI.M with the given input arguments.
%
%      FLY_ANALYZEDATAGUI('Property','Value',...) creates a new FLY_ANALYZEDATAGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before fly_analyzeDataGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to fly_analyzeDataGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help fly_analyzeDataGUI

% Last Modified by GUIDE v2.5 19-Feb-2014 12:16:03

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @fly_analyzeDataGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @fly_analyzeDataGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before fly_analyzeDataGUI is made visible.
function fly_analyzeDataGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to fly_analyzeDataGUI (see VARARGIN)

% Choose default command line output for fly_analyzeDataGUI

extractionParams.freqsToExtract=[1 0;0 1;2 0;0 2;1 1;2 2];
extractionParams.freqLabels={'F1','F2','2F1','2F2','F2+F1','2F2+2F1'};
extractionParams.incoherentAvMaxFreq=100; % Hz
extractionParams.rejectParams.sd=2;
extractionParams.rejectParams.maxFreq=100; % Hz
extractionParams.DOFILENORM=0;
extractionParams.SNRFLAG=0;
extractionParams.waveformSampleRate=1000; % Hz. Resample the average waveform to this rate irrespective of the initial rate.
extractionParams.dataChannelIndices=[1 2 3];

handles.output = hObject;
handles.allData=[];
handles.plotParams=[];
handles.extractionParams=extractionParams;
handles.exptParams=[];

handles.saveParams=[];

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes fly_analyzeDataGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = fly_analyzeDataGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function TopLevelDirectory_Callback(hObject, eventdata, handles)
% hObject    handle to TopLevelDirectory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of TopLevelDirectory as text
%        str2double(get(hObject,'String')) returns contents of TopLevelDirectory as a double


% --- Executes during object creation, after setting all properties.
function TopLevelDirectory_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TopLevelDirectory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in SelectDirectory.
function SelectDirectory_Callback(hObject, eventdata, handles)
% hObject    handle to SelectDirectory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
a=uigetdir(pwd);
set(handles.TopLevelDirectory,'String',char(a));
set(handles.LoadedStatus,'BackgroundColor',[1 0 0]);
set(handles.LoadedStatus,'String','Not loaded');

% --- Executes on button press in NoiseCheck.
function NoiseCheck_Callback(hObject, eventdata, handles)
% hObject    handle to NoiseCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of NoiseCheck


% --- Executes on button press in OpenGL.
function OpenGL_Callback(hObject, eventdata, handles)
% hObject    handle to OpenGL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of OpenGL


% --- Executes on button press in DoFitting.
function DoFitting_Callback(hObject, eventdata, handles)
% hObject    handle to DoFitting (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of DoFitting


% --- Executes on button press in ShowPhotodiode.
function ShowPhotodiode_Callback(hObject, eventdata, handles)
% hObject    handle to ShowPhotodiode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ShowPhotodiode


% --- Executes on button press in FreqCheck_1.
function FreqCheck_1_Callback(hObject, eventdata, handles)
% hObject    handle to FreqCheck_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of FreqCheck_1


% --- Executes on button press in FreqCheck_3.
function FreqCheck_3_Callback(hObject, eventdata, handles)
% hObject    handle to FreqCheck_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of FreqCheck_3


% --- Executes on button press in FreqCheck_2.
function FreqCheck_2_Callback(hObject, eventdata, handles)
% hObject    handle to FreqCheck_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of FreqCheck_2


% --- Executes on button press in FreqCheck_4.
function FreqCheck_4_Callback(hObject, eventdata, handles)
% hObject    handle to FreqCheck_4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of FreqCheck_4


% --- Executes on button press in FreqCheck_5.
function FreqCheck_5_Callback(hObject, eventdata, handles)
% hObject    handle to FreqCheck_5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of FreqCheck_5


% --- Executes on button press in FreqCheck_6.
function FreqCheck_6_Callback(hObject, eventdata, handles)
% hObject    handle to FreqCheck_6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of FreqCheck_6


% --- Executes on button press in FreqCheck7.
function FreqCheck7_Callback(hObject, eventdata, handles)
% hObject    handle to FreqCheck7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of FreqCheck7


% --- Executes on button press in FreqCheck_8.
function FreqCheck_8_Callback(hObject, eventdata, handles)
% hObject    handle to FreqCheck_8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of FreqCheck_8


% --- Executes on button press in PlotOpt1.
function PlotOpt1_Callback(hObject, eventdata, handles)
% hObject    handle to PlotOpt1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of PlotOpt1


% --- Executes on button press in PlotOpt2.
function PlotOpt2_Callback(hObject, eventdata, handles)
% hObject    handle to PlotOpt2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of PlotOpt2


% --- Executes on button press in PlotOpt3.
function PlotOpt3_Callback(hObject, eventdata, handles)
% hObject    handle to PlotOpt3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of PlotOpt3


% --- Executes on button press in PlotOpt4.
function PlotOpt4_Callback(hObject, eventdata, handles)
% hObject    handle to PlotOpt4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of PlotOpt4


% --- Executes on button press in PlotDataButton.
function PlotDataButton_Callback(hObject, eventdata, handles)
% hObject    handle to PlotDataButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in LoadDataButton.
function LoadDataButton_Callback(hObject, eventdata, handles)
% hObject    handle to LoadDataButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Loads the data from the directory in handles.TopLevelDirectory into a
% global data structure...

%% Here we load in all the different data files.
baseDir=get(handles.TopLevelDirectory,'String');
subDirList=fly_getDataDirectories_multi(baseDir); % This function generates the locations of all the directories..
[a,b]=fileparts(baseDir);
[handles.allData,handles.exptParams]=fly_loadSSData(subDirList,handles.extractionParams);
set(handles.LoadedStatus,'BackgroundColor',[0 1 0]);
set(handles.LoadedStatus,'String','Loaded');
% Update handles structure
guidata(hObject, handles);

