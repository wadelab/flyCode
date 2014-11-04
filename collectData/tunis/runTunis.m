function varargout = runTunis(varargin)
% RUNTUNIS MATLAB code for runTunis.fig
%      RUNTUNIS, by itself, creates a new RUNTUNIS or raises the existing
%      singleton*.
%
%      H = RUNTUNIS returns the handle to a new RUNTUNIS or the handle to
%      the existing singleton*.
%
%      RUNTUNIS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RUNTUNIS.M with the given input arguments.
%
%      RUNTUNIS('Property','Value',...) creates a new RUNTUNIS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before runTunis_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to runTunis_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help runTunis

% Last Modified by GUIDE v2.5 27-Oct-2014 19:05:38

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @runTunis_OpeningFcn, ...
                   'gui_OutputFcn',  @runTunis_OutputFcn, ...
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


% --- Executes just before runTunis is made visible.
function runTunis_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to runTunis (see VARARGIN)

% Choose default command line output for runTunis
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes runTunis wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = runTunis_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in goButton.
function goButton_Callback(hObject, eventdata, handles)
% hObject    handle to goButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% This is the only important button. It calls the EEG stim loop passing in
% the parameters of subject ID and group. 
handles.exitFlag=1;
guidata(hObject,handles);
disp(handles)
disp(hObject)
patientID=get(handles.PatientID,'String');
groupID=get(handles.groupListBox,'String');
groupIDSelected=get(handles.groupListBox,'Value');
fprintf('\nPatient ID %s, Group %s',char(patientID),char(groupID{groupIDSelected}));
patientInfo.ID=char(patientID);
patientInfo.group=char(groupID{groupIDSelected});
patientInfo.runTime=now;
patientInfo.pwd=pwd;
runMainLoopTunis(patientInfo);

%uiresume;

function PatientID_Callback(hObject, eventdata, handles)
% hObject    handle to PatientID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of PatientID as text
%        str2double(get(hObject,'String')) returns contents of PatientID as a double


% --- Executes during object creation, after setting all properties.
function PatientID_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PatientID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in groupListBox.
function groupListBox_Callback(hObject, eventdata, handles)
% hObject    handle to groupListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns groupListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from groupListBox


% --- Executes during object creation, after setting all properties.
function groupListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to groupListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
