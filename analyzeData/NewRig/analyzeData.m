function varargout = analyzeData(varargin)
% ANALYZEDATA MATLAB code for analyzeData.fig
%      ANALYZEDATA, by itself, creates a new ANALYZEDATA or raises the existing
%      singleton*.
%
%      H = ANALYZEDATA returns the handle to a new ANALYZEDATA or the handle to
%      the existing singleton*.
%
%      ANALYZEDATA('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ANALYZEDATA.M with the given input arguments.
%
%      ANALYZEDATA('Property','Value',...) creates a new ANALYZEDATA or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before analyzeData_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to analyzeData_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help analyzeData

% Last Modified by GUIDE v2.5 18-Feb-2014 14:40:25

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @analyzeData_OpeningFcn, ...
                   'gui_OutputFcn',  @analyzeData_OutputFcn, ...
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


% --- Executes just before analyzeData is made visible.
function analyzeData_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to analyzeData (see VARARGIN)

% Choose default command line output for analyzeData
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes analyzeData wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = analyzeData_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


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
