function varargout = FlyGUI1(varargin)
% FLYGUI1 MATLAB code for FlyGUI1.fig
% Runs the GUI for preparing a data structure in the fly_runExperiment
% functions
% ARW 10.18.13: Wrote it based loosely on earlier GUIs
%
%      FLYGUI1, by itself, creates a new FLYGUI1 or raises the existing
%      singleton*.
%
%      H = FLYGUI1 returns the handle to a new FLYGUI1 or the handle to
%      the existing singleton*.
%
%      FLYGUI1('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FLYGUI1.M with the given input arguments.
%
%      FLYGUI1('Property','Value',...) creates a new FLYGUI1 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before FlyGUI1_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to FlyGUI1_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help FlyGUI1

% Last Modified by GUIDE v2.5 17-Mar-2014 12:24:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @FlyGUI1_OpeningFcn, ...
    'gui_OutputFcn',  @FlyGUI1_OutputFcn, ...
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


% --- Executes just before FlyGUI1 is made visible.
function FlyGUI1_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to FlyGUI1 (see VARARGIN)

% Choose default command line output for FlyGUI1
handles.output = hObject;



% Update handles structure
guidata(hObject, handles);
handles.exitFlag=0;
guidata(hObject,handles);

% We want to be able to pass in a struct (b) and have it populate the
% 'value' fields of all the GUI elements. The lazy way would be to iterate
% through children of hObject, assuming that they are in the same order as
% b{1...}
% But if we add something to the GUI, old files will break this function.
% Better to match up 'tags' from the GUI and the struct and assign values
% that way.
if (iscell(varargin) & ~isempty(varargin))

if (iscell(varargin{1})) % If we were passed a cell array, parse it and do some value setting...
    children=findall(hObject);
    % f=allchild(hObject);
    nChild=length(children);
    outputIndex=1;
    for thisChild=2:nChild
        
        % Get the tag from this field in the GUI
        d=get(children(thisChild));
       
        tagField{thisChild}=d.Tag;
    end
    b=varargin{1};
    for thisInputEntry=1:length(b)
        disp(thisInputEntry)
        
        if (isfield(b{thisInputEntry},'tag'))
           disp('Found tag field');
            thisTag=b{thisInputEntry}.tag
            if (length(thisTag)>0)
                           disp('non-null tag name');

                tagIndex=find(strcmp(tagField,thisTag));
                if (length(tagIndex)>1) % Error check
                    disp(thisTag);
                    error('More than one GUI field with the same tag');
                end
                fprintf('\nTag Index = %d',tagIndex);
                if (~isempty(tagIndex))
                    % Set the value
                    if (isfield(b{thisInputEntry},'value'))
                        disp('*** SETTING ***');
                        
                        thisValue=b{thisInputEntry}.value;
                        
                        if (thisValue~=0)
                            disp(get(children(thisChild)))
                          set(children(tagIndex),'value',thisValue);
                        end
                        
                    end % End check on presence of value
                end % End check on empty tagIndex
            end % End Check on length tag == 0
        end % End check on input Tag presence
    end % Next input entry
    
    
end % End check on whether an input cell array was passed
end % End check on whether any arguments were passed

guidata(hObject,handles);
% UIWAIT makes FlyGUI1 wait for user response (see UIRESUME)


%axes(handles.axes5);
%imshow('wobbleWave.gif');
%axes(handles.axes6);
%imshow('fly.gif');
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = FlyGUI1_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
d=get(hObject);
size(d);
disp(d);
children=findall(hObject);
f=allchild(hObject);
nChild=length(children);
outputIndex=1;
for thisChild=1:nChild
    
    
    d=get(children(thisChild));
    if(isfield(d,'Value'))
        outData{thisChild}.value=d.Value;
    end
    if(isfield(d,'Selected'))
        outData{thisChild}.selected=d.Selected;
    end
    if(isfield(d,'String'))
        outData{thisChild}.string=d.String;
    end
    
    outData{thisChild}.tag=get(children(thisChild),'Tag');
end


varargout{2} = outData;
varargout{3} = handles.exitFlag;
close(handles.figure1)

% --- Executes on selection change in FlyType2.
function FlyType2_Callback(hObject, eventdata, handles)
% hObject    handle to FlyType2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns FlyType2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from FlyType2


% --- Executes during object creation, after setting all properties.
function FlyType2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FlyType2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
set(hObject,'String','ort-');


% --- Executes on selection change in GAL4Fly1.
function GAL4Fly1_Callback(hObject, eventdata, handles)
% hObject    handle to GAL4Fly1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns GAL4Fly1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from GAL4Fly1


% --- Executes during object creation, after setting all properties.
function GAL4Fly1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to GAL4Fly1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in F1FreqList.
function F1FreqList_Callback(hObject, eventdata, handles)
% hObject    handle to F1FreqList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns F1FreqList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from F1FreqList


% --- Executes during object creation, after setting all properties.
function F1FreqList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to F1FreqList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in F2FreqList.
function F2FreqList_Callback(hObject, eventdata, handles)
% hObject    handle to F2FreqList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns F2FreqList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from F2FreqList


% --- Executes during object creation, after setting all properties.
function F2FreqList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to F2FreqList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in F2LED4.
function F2LED4_Callback(hObject, eventdata, handles)
% hObject    handle to F2LED4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of F2LED4


% --- Executes on button press in F2LED3.
function F2LED3_Callback(hObject, eventdata, handles)
% hObject    handle to F2LED3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of F2LED3


% --- Executes on button press in F2LED2.
function F2LED2_Callback(hObject, eventdata, handles)
% hObject    handle to F2LED2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of F2LED2


% --- Executes on button press in F2LED1.
function F2LED1_Callback(hObject, eventdata, handles)
% hObject    handle to F2LED1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of F2LED1



function ExpNotes_Callback(hObject, eventdata, handles)
% hObject    handle to ExpNotes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ExpNotes as text
%        str2double(get(hObject,'String')) returns contents of ExpNotes as a double


% --- Executes during object creation, after setting all properties.
function ExpNotes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ExpNotes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in F1LED4.
function F1LED4_Callback(hObject, eventdata, handles)
% hObject    handle to F1LED4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of F1LED4


% --- Executes on button press in F1LED3.
function F1LED3_Callback(hObject, eventdata, handles)
% hObject    handle to F1LED3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of F1LED3


% --- Executes on button press in F1LED2.
function F1LED2_Callback(hObject, eventdata, handles)
% hObject    handle to F1LED2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of F1LED2


% --- Executes on button press in F1LED1.
function F1LED1_Callback(hObject, eventdata, handles)
% hObject    handle to F1LED1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of F1LED1


% --- Executes on selection change in ExperimenterList.
function ExperimenterList_Callback(hObject, eventdata, handles)
% hObject    handle to ExperimenterList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ExperimenterList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ExperimenterList


% --- Executes during object creation, after setting all properties.
function ExperimenterList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ExperimenterList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in Fly1AgeDays.
function Fly1AgeDays_Callback(hObject, eventdata, handles)
% hObject    handle to Fly1AgeDays (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Fly1AgeDays contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Fly1AgeDays


% --- Executes during object creation, after setting all properties.
function Fly1AgeDays_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Fly1AgeDays (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in ATag2.
function Fly2AgeDays_Callback(hObject, eventdata, handles)
% hObject    handle to ATag2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ATag2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ATag2


% --- Executes during object creation, after setting all properties.
function ATag2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ATag2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in GoButton.
function GoButton_Callback(hObject, eventdata, handles)
% hObject    handle to GoButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.exitFlag=1;
guidata(hObject,handles);
uiresume;
% --- Executes during object creation, after setting all properties.
function Fly2AgeDays_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Fly2AgeDays (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in CancelButton.
function CancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to CancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.exitFlag=-1;
guidata(hObject,handles);
uiresume


% --- Executes on selection change in UASListFly1.
function UASListFly1_Callback(hObject, eventdata, handles)
% hObject    handle to UASListFly1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns UASListFly1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from UASListFly1


% --- Executes during object creation, after setting all properties.
function UASListFly1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to UASListFly1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in OtherTypeListFly1.
function OtherTypeListFly1_Callback(hObject, eventdata, handles)
% hObject    handle to OtherTypeListFly1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns OtherTypeListFly1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from OtherTypeListFly1


% --- Executes during object creation, after setting all properties.
function OtherTypeListFly1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to OtherTypeListFly1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in DrugFly1List.
function DrugFly1List_Callback(hObject, eventdata, handles)
% hObject    handle to DrugFly1List (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns DrugFly1List contents as cell array
%        contents{get(hObject,'Value')} returns selected item from DrugFly1List


% --- Executes during object creation, after setting all properties.
function DrugFly1List_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DrugFly1List (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in ConcFly1List.
function ConcFly1List_Callback(hObject, eventdata, handles)
% hObject    handle to ConcFly1List (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ConcFly1List contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ConcFly1List


% --- Executes during object creation, after setting all properties.
function ConcFly1List_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ConcFly1List (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in DrugAdminFly1List.
function DrugAdminFly1List_Callback(hObject, eventdata, handles)
% hObject    handle to DrugAdminFly1List (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns DrugAdminFly1List contents as cell array
%        contents{get(hObject,'Value')} returns selected item from DrugAdminFly1List


% --- Executes during object creation, after setting all properties.
function DrugAdminFly1List_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DrugAdminFly1List (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in GAL4Fly2.
function GAL4Fly2_Callback(hObject, eventdata, handles)
% hObject    handle to GAL4Fly2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns GAL4Fly2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from GAL4Fly2


% --- Executes during object creation, after setting all properties.
function GAL4Fly2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to GAL4Fly2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in UASListFly2.
function UASListFly2_Callback(hObject, eventdata, handles)
% hObject    handle to UASListFly2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns UASListFly2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from UASListFly2


% --- Executes during object creation, after setting all properties.
function UASListFly2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to UASListFly2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in OtherTypeListFly2.
function OtherTypeListFly2_Callback(hObject, eventdata, handles)
% hObject    handle to OtherTypeListFly2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns OtherTypeListFly2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from OtherTypeListFly2


% --- Executes during object creation, after setting all properties.
function OtherTypeListFly2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to OtherTypeListFly2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in DrugFly2List.
function DrugFly2List_Callback(hObject, eventdata, handles)
% hObject    handle to DrugFly2List (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns DrugFly2List contents as cell array
%        contents{get(hObject,'Value')} returns selected item from DrugFly2List


% --- Executes during object creation, after setting all properties.
function DrugFly2List_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DrugFly2List (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in ConcFly2List.
function ConcFly2List_Callback(hObject, eventdata, handles)
% hObject    handle to ConcFly2List (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ConcFly2List contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ConcFly2List


% --- Executes during object creation, after setting all properties.
function ConcFly2List_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ConcFly2List (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in DrugAdminFly2List.
function DrugAdminFly2List_Callback(hObject, eventdata, handles)
% hObject    handle to DrugAdminFly2List (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns DrugAdminFly2List contents as cell array
%        contents{get(hObject,'Value')} returns selected item from DrugAdminFly2List


% --- Executes during object creation, after setting all properties.
function DrugAdminFly2List_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DrugAdminFly2List (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in Fly2AgeDays.
function listbox14_Callback(hObject, eventdata, handles)
% hObject    handle to Fly2AgeDays (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Fly2AgeDays contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Fly2AgeDays


% --- Executes during object creation, after setting all properties.
function listbox14_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Fly2AgeDays (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in LED1.
function LED1_Callback(hObject, eventdata, handles)
% hObject    handle to LED1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of LED1


% --- Executes on selection change in ExperimentTypeList.
function ExperimentTypeList_Callback(hObject, eventdata, handles)
% hObject    handle to ExperimentTypeList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ExperimentTypeList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ExperimentTypeList


% --- Executes during object creation, after setting all properties.
function ExperimentTypeList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ExperimentTypeList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in nRepeatsList.
function nRepeatsList_Callback(hObject, eventdata, handles)
% hObject    handle to nRepeatsList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns nRepeatsList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from nRepeatsList


% --- Executes during object creation, after setting all properties.
function nRepeatsList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nRepeatsList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
