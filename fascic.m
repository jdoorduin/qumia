function varargout = fascic(varargin)
% FASCIC M-file for fascic.fig
%      FASCIC, by itself, creates a new FASCIC or raises the existing
%      singleton*.
%
%      H = FASCIC returns the handle to a new FASCIC or the handle to
%      the existing singleton*.
%
%      FASCIC('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FASCIC.M with the given input arguments.
%
%      FASCIC('Property','Value',...) creates a new FASCIC or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before fasciculaties_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to fascic_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help fascic

% Last Modified by GUIDE v2.5 16-Jul-2014 15:33:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @fascic_OpeningFcn, ...
                   'gui_OutputFcn',  @fascic_OutputFcn, ...
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


% --- Executes just before fascic is made visible.
function fascic_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to fascic (see VARARGIN)

% Update handles structure
guidata(hObject, handles);

%% 2014-05-06 GW changed towards new musclelist
% was:
% load 'musclestruct2';
% ud.musclestruct=muscle;
%
% converted new styled musclesturct to old styled struct in order to let this module
% work...
%
% new:
ud = get(findobj('Tag','figure1'),'UserData');

list=ud.musclestruct.name;
[list_alfabetic n_list_alfabetic]= sort(list); % list alfabetically, Doorduin 04-11-2014
list_alfabetic = [' ';list_alfabetic];

for i=1:20
    eval(['h(i)=handles.muscle',num2str(i),';']);
    set(h(i),'string',list_alfabetic);
end

if nargin>3
    restoredata=varargin{1};
    unique_name = unique(restoredata.name);
    for i=1:length(unique_name)
        
        idx=find(strcmp(unique_name(i),list_alfabetic)==1);
        
        if ~isempty(idx)
            eval(['set(handles.muscle',num2str(i),',''value'',',num2str(idx),');']);
            
            idx2=find(strcmp(unique_name(i),restoredata.name)==1);
            
            if strcmp(restoredata.side{idx2(1)},'l');
                eval(['set(handles.l',num2str(i),',''value'',',num2str(restoredata.value(idx2(1))+2),');']);
            elseif  strcmp(restoredata.side{idx2(1)},'r');
                eval(['set(handles.r',num2str(i),',''value'',',num2str(restoredata.value(idx2(1))+2),');']);
            end;
            
            if length(idx2)>1
                if strcmp(restoredata.side{idx2(2)},'l');
                    eval(['set(handles.l',num2str(i),',''value'',',num2str(restoredata.value(idx2(2))+2),');']);
                elseif  strcmp(restoredata.side{idx2(2)},'r');
                    eval(['set(handles.r',num2str(i),',''value'',',num2str(restoredata.value(idx2(2))+2),');']);
                end;
            end;
            
        end
    end;
else    
    choice = questdlg('Standard MND protocol fasciculations?','','Yes','No','Yes');
    switch choice
        case 'Yes'
            %standard preset muscles for fasciculation screening
            
            MND_protocol_muscles = {'Digastricus','Geniohyoideus','Masseter','Sterno cleido','Trapezius','Biceps brachii',...
                'Flexor carpi radialis','Interosseus dorsalis I','Rectus abdominis','Rectus femoris','Tibialis anterior','Gastrocnemius medial head'};
            for j=1:length(MND_protocol_muscles)
            preset_idx(j) = find(strcmp(list_alfabetic,MND_protocol_muscles{j})==1);
            end

            for i=1:length(preset_idx)
                eval(['set(handles.muscle',num2str(i),',''value'',',num2str(preset_idx(i)),');']);
                eval(['set(handles.l' num2str(i) ',''value'',2);' ]);
                eval(['set(handles.r' num2str(i) ',''value'',2);' ]);
            end
    end
end

set(gcf,'userdata',ud);

%UIWAIT makes fascic wait for user response (see UIRESUME)
uiwait(handles.fasc);

% --- Outputs from this function are returned to the command line.
function varargout = fascic_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = [];
if ~isempty(handles)
    ud=get(gcf,'userdata');
    if ud.ok
        varargout{1} = ud.r;
    end;
    close(gcf);
end;

% --- Executes on button press in ok.
function ok_Callback(hObject, eventdata, handles)
% hObject    handle to ok (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ud=get(gcf,'userdata');
r=[];
for i=1:20
    eval(['h(i)=handles.muscle',num2str(i),';']);
end;

fascval=[-1 0 1 2 3];
j=1;
for i=1:length(h)
    
    v=get(h(i),'value');
    if v>1
        
        s=get(h(i),'string');
        eval(['fl=get(handles.l',num2str(i),',''value'');']);
        eval(['fr=get(handles.r',num2str(i),',''value'');']);
        
        for sides=[1 2]
            if fl>1 || fr>1
                r.name{j}=char(s(v));
                r.key(j)=ud.musclestruct.key(strcmp(ud.musclestruct.name,r.name{j}));
                
                if sides==1
                    if fl>1
                        r.side{j}='l';
                        r.value(j)=fascval(fl);
                    end;
                else
                    if fr>1
                        r.side{j}='r';
                        r.value(j)=fascval(fr);
                    end;
                end
                
                j=j+1;
                
            end;
        end
        
    end;
end;

ud.r=r;
ud.ok=1;
set(gcf,'userdata',ud);
uiresume;

% --- Executes on button press in cancel.
function cancel_Callback(hObject, eventdata, handles)
% hObject    handle to cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ud=get(gcf,'userdata');
ud.ok=0;
set(gcf,'userData',ud);
uiresume;

% --- Executes on selection change in muscle1.
function muscle1_Callback(hObject, eventdata, handles)
% hObject    handle to muscle1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns muscle1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from muscle1


% --- Executes during object creation, after setting all properties.
function muscle1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to muscle1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in muscle2.
function muscle2_Callback(hObject, eventdata, handles)
% hObject    handle to muscle2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns muscle2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from muscle2


% --- Executes during object creation, after setting all properties.
function muscle2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to muscle2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in muscle3.
function muscle3_Callback(hObject, eventdata, handles)
% hObject    handle to muscle3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns muscle3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from muscle3


% --- Executes during object creation, after setting all properties.
function muscle3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to muscle3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in muscle4.
function muscle4_Callback(hObject, eventdata, handles)
% hObject    handle to muscle4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns muscle4 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from muscle4


% --- Executes during object creation, after setting all properties.
function muscle4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to muscle4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in muscle5.
function muscle5_Callback(hObject, eventdata, handles)
% hObject    handle to muscle5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns muscle5 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from muscle5


% --- Executes during object creation, after setting all properties.
function muscle5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to muscle5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in muscle6.
function muscle6_Callback(hObject, eventdata, handles)
% hObject    handle to muscle6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns muscle6 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from muscle6


% --- Executes during object creation, after setting all properties.
function muscle6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to muscle6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in muscle7.
function muscle7_Callback(hObject, eventdata, handles)
% hObject    handle to muscle7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns muscle7 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from muscle7


% --- Executes during object creation, after setting all properties.
function muscle7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to muscle7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in muscle8.
function muscle8_Callback(hObject, eventdata, handles)
% hObject    handle to muscle8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns muscle8 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from muscle8


% --- Executes during object creation, after setting all properties.
function muscle8_CreateFcn(hObject, eventdata, handles)
% hObject    handle to muscle8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in muscle9.
function muscle9_Callback(hObject, eventdata, handles)
% hObject    handle to muscle9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns muscle9 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from muscle9


% --- Executes during object creation, after setting all properties.
function muscle9_CreateFcn(hObject, eventdata, handles)
% hObject    handle to muscle9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in muscle10.
function muscle10_Callback(hObject, eventdata, handles)
% hObject    handle to muscle10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns muscle10 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from muscle10


% --- Executes during object creation, after setting all properties.
function muscle10_CreateFcn(hObject, eventdata, handles)
% hObject    handle to muscle10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in muscle11.
function muscle11_Callback(hObject, eventdata, handles)
% hObject    handle to muscle11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns muscle11 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from muscle11


% --- Executes during object creation, after setting all properties.
function muscle11_CreateFcn(hObject, eventdata, handles)
% hObject    handle to muscle11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in l11.
function l11_Callback(hObject, eventdata, handles)
% hObject    handle to l11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns l11 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from l11


% --- Executes during object creation, after setting all properties.
function l11_CreateFcn(hObject, eventdata, handles)
% hObject    handle to l11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in l10.
function l10_Callback(hObject, eventdata, handles)
% hObject    handle to l10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns l10 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from l10


% --- Executes during object creation, after setting all properties.
function l10_CreateFcn(hObject, eventdata, handles)
% hObject    handle to l10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in l9.
function l9_Callback(hObject, eventdata, handles)
% hObject    handle to l9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns l9 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from l9


% --- Executes during object creation, after setting all properties.
function l9_CreateFcn(hObject, eventdata, handles)
% hObject    handle to l9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in l8.
function l8_Callback(hObject, eventdata, handles)
% hObject    handle to l8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns l8 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from l8


% --- Executes during object creation, after setting all properties.
function l8_CreateFcn(hObject, eventdata, handles)
% hObject    handle to l8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in l7.
function l7_Callback(hObject, eventdata, handles)
% hObject    handle to l7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns l7 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from l7


% --- Executes during object creation, after setting all properties.
function l7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to l7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in l6.
function l6_Callback(hObject, eventdata, handles)
% hObject    handle to l6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns l6 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from l6


% --- Executes during object creation, after setting all properties.
function l6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to l6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in l5.
function l5_Callback(hObject, eventdata, handles)
% hObject    handle to l5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns l5 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from l5


% --- Executes during object creation, after setting all properties.
function l5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to l5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in l4.
function l4_Callback(hObject, eventdata, handles)
% hObject    handle to l4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns l4 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from l4


% --- Executes during object creation, after setting all properties.
function l4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to l4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in l3.
function l3_Callback(hObject, eventdata, handles)
% hObject    handle to l3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns l3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from l3


% --- Executes during object creation, after setting all properties.
function l3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to l3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in l2.
function l2_Callback(hObject, eventdata, handles)
% hObject    handle to l2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns l2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from l2


% --- Executes during object creation, after setting all properties.
function l2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to l2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in l1.
function l1_Callback(hObject, eventdata, handles)
% hObject    handle to l1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns l1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from l1


% --- Executes during object creation, after setting all properties.
function l1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to l1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

