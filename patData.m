function varargout = patData(varargin)
%% Parameter info
% Vargout returns a struct containing patient and laborant information
% varargout = patData(struct, edit)
% input1 : dicom struct
% input2 : 
% output: struct
%           ****.patient.naam
%           ****.patient.leeftijd
%           ......
%           ****.laborant.naam

%% file info
% PATDATA M-file for patData.fig
%      PATDATA, by itself, creates a new PATDATA or raises the existing
%      singleton*.
%
%      H = PATDATA returns the handle to a new PATDATA or the handle to
%      the existing singleton*.
%
%      PATDATA('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PATDATA.M with the given input arguments.
%
%      PATDATA('Property','Value',...) creates a new PATDATA or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before patData_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to patData_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help patData

% Last Modified by GUIDE v2.5 14-Dec-2011 14:48:02

%% init
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @patData_OpeningFcn, ...
                   'gui_OutputFcn',  @patData_OutputFcn, ...
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

% --- Executes just before patData is made visible.
function patData_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to patData (see VARARGIN)

% Choose default command line output for patData
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

%% Set the parameters from dicom struct
%if size(varargin,2)==2 && ischar(varargin{2})
if  ~isnumeric(varargin{1,2}) 
    info = varargin{1};
    laborant = varargin{2};
    if ~ischar(info.PatientID)
        info.PatientID=num2str(info.PatientID);
    end;
    set(handles.sPatNr,'String',info.PatientID);
    set(handles.sName,'String',info.PatientName.FamilyName);
    while isempty(info.PatientBirthDate)
        info.PatientBirthDate=inputdlg('Enter patient birthdate [yyyymmdd]: ','No birthdate in DCM file');
    end;
    geboortedatum = datestr(datenum(info.PatientBirthDate,'yyyymmdd'),'dd-mm-yyyy');
    set(handles.sGeboorteDatum,'String',geboortedatum);
    while isempty(info.PatientSex)
        info.PatientSex=char(inputdlg('Enter patient sex [F/M]: ','No PatientSex in DCM file'));
    end;
    set(handles.sGeslacht,'String',info.PatientSex);
    meetdatum = datestr(datenum(info.StudyDate,'yyyymmdd'),'dd-mm-yyyy');
    set(handles.sMeetDatum,'String',meetdatum);
    %% Calculate age
    datenumGeboortedatum  = datenum(info.PatientBirthDate,'yyyymmdd');
    datenumMeetdatum      = datenum(info.StudyDate,'yyyymmdd');
    datenumLeeftijd       = datenumMeetdatum - datenumGeboortedatum;
    leeftijd =  datenumLeeftijd/365.25;
    set(handles.sLeeftijd,'String',leeftijd);
    if ~isempty(laborant)
        set(handles.popLaborant,'String',laborant);
    end;

%else if size(varargin,2)==2 && varargin{2}==1;
else if varargin{1,2}==1 || strcmp(varargin{1,2},'')
        if ~isempty(varargin{1})
            
            res = varargin{1};
            res=checkpatientstruct(res); % check input info add fields if required
            
            if ~ischar(res.patient.patientid)
                res.patient.patientid=num2str(res.patient.patientid);
            end;
            set(handles.sPatNr,'String',res.patient.patientid);
            set(handles.sName,'String',res.patient.name);
            set(handles.sGeboorteDatum,'String',res.patient.geboortedatum);
            set(handles.sLengte,'String',res.patient.lengte);
            set(handles.sGewicht,'String',res.patient.gewicht);
            set(handles.sGeslacht,'String',res.patient.geslacht);
            set(handles.sMeetDatum,'String',res.patient.meetdatum);
            updateleeftijd(handles);
            
            if ~isempty(res.laborant.naam)
                set(handles.popLaborant,'String',res.laborant.naam);
            end;
            string_list = get(handles.popKant,'String');
            if ~isempty(res.patient.kant)
                index = getIndex(string_list, res.patient.kant, 3);
            else
                index=1;
            end;
            set(handles.popKant,'value',index);

        %     string_list = get(handles.popLaborant,'String');
        %     nrElements = size(string_list,1);
        %     index = getIndex(string_list, res.laborant.naam, nrElements);
        %     set(handles.popLaborant,'value',index);
        else
            enable_edit(handles);
        end;
    else
    fprintf('Too many arguments or wrong arguments\nusage \tres = patData(dicomstruct) \n\t\tres = patData(res,1)\n');    
    return;
    end;
end;

%% UIWAIT makes patData wait for user response (see UIRESUME)
uiwait(handles.figure1);


%% Set output
% --- Outputs from this function are returned to the command line.


function p=checkpatientstruct(p)
% check field names and add is required
if ~isfield(p.patient,'geboortedatum')
    p.patient.geboortedatum=[];
end;
if ~isfield(p.patient,'name')
    p.patient.name=[];
end;
if ~isfield(p.patient,'lengte')
    p.patient.lengte=[];
end;
if ~isfield(p.patient,'gewicht')
    p.patient.gewicht=[];
end;
if ~isfield(p.patient,'geslacht')
    p.patient.geslacht=[];
end;
if ~isfield(p.patient,'leeftijd')
    p.patient.leeftijd=[];
end;
if ~isfield(p.patient,'meetdatum')
    p.patient.meetdatum=[];
end;
if ~isfield(p.patient,'kant')
    p.patient.kant=[];
end;
if ~isfield(p.patient,'patientid')
    p.patient.patientid=[];
end;
if ~isfield(p,'laborant')
    p.laborant=[];
end;
    



function varargout = patData_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if ~isempty(handles)
    varargout{1} = get(handles.figure1,'userdata');
    delete(handles.figure1);
end;



%% Create userinterface elements
function sGeboortedatum_Callback(hObject, eventdata, handles)
% hObject    handle to sGeboortedatum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sGeboortedatum as text
%        str2double(get(hObject,'String')) returns contents of sGeboortedatum as a double


% --- Executes during object creation, after setting all properties.
function sGeboortedatum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sGeboortedatum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function sGewicht_Callback(hObject, eventdata, handles)
% hObject    handle to sGewicht (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sGewicht as text
%        str2double(get(hObject,'String')) returns contents of sGewicht as a double
tmp = get(hObject,'String');
chkinput(tmp,gco);

% --- Executes during object creation, after setting all properties.
function sGewicht_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sGewicht (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function sLeeftijd_Callback(hObject, eventdata, handles)
% hObject    handle to sLeeftijd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sLeeftijd as text
%        str2double(get(hObject,'String')) returns contents of sLeeftijd as a double


% --- Executes during object creation, after setting all properties.
function sLeeftijd_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sLeeftijd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function sPatNr_Callback(hObject, eventdata, handles)
% hObject    handle to sPatNr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sPatNr as text
%        str2double(get(hObject,'String')) returns contents of sPatNr as a double


% --- Executes during object creation, after setting all properties.
function sPatNr_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sPatNr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function sMeetDatum_Callback(hObject, eventdata, handles)
% hObject    handle to sMeetDatum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sMeetDatum as text
%        str2double(get(hObject,'String')) returns contents of sMeetDatum as a double

% get geb. datum, if notempty calculate age
updateleeftijd(handles);

function updateleeftijd(handles)
try
gebd=get(handles.sGeboorteDatum,'String');
meetd=get(handles.sMeetDatum,'String');
if ~isempty(gebd) && ~isempty(meetd)
    datenumGeboortedatum  = datenum(gebd,'dd-mm-yyyy');
    datenumMeetdatum      = datenum(meetd,'dd-mm-yyyy');
    datenumLeeftijd       = datenumMeetdatum - datenumGeboortedatum;
    leeftijd =  datenumLeeftijd/365.25;
    set(handles.sLeeftijd,'String',num2str(leeftijd));
end;
catch
    errordlg('Invalid date');
    uiwait;
end;

% --- Executes during object creation, after setting all properties.
function sMeetDatum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sMeetDatum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function sLengte_Callback(hObject, eventdata, handles)
% hObject    handle to sLengte (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sLengte as text
%        str2double(get(hObject,'String')) returns contents of sLengte as a double
tmp = get(hObject,'String');
chkinput(tmp,gco);
if str2num(tmp)<30
    errordlg('Error: length must be entered in cm','Error in length','modal');
    set(hObject,'String',[]);
end;
% if (~isempty(tmp) && isnan(str2double(tmp)))
%     uicontrol(gco);
%     errordlg({'Fout in het ingevoerde getal'},'Foutieve invoer');
% end

% --- Executes during object creation, after setting all properties.
function sLengte_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sLengte (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function sGeslacht_Callback(hObject, eventdata, handles)
% hObject    handle to sGeslacht (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sGeslacht as text
%        str2double(get(hObject,'String')) returns contents of sGeslacht as a double

% --- Executes during object creation, after setting all properties.
function sGeslacht_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sGeslacht (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function sGeboorteDatum_Callback(hObject, eventdata, handles)
% hObject    handle to sGeboorteDatum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sGeboorteDatum as text
%        str2double(get(hObject,'String')) returns contents of sGeboorteDatum as a double
% check date

updateleeftijd(handles);

% --- Executes during object creation, after setting all properties.
function sKant_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sGeboorteDatum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function sKant_Callback(hObject, eventdata, handles)
% hObject    handle to sGeboorteDatum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sGeboorteDatum as text
%        str2double(get(hObject,'String')) returns contents of sGeboorteDatum as a double

% --- Executes during object creation, after setting all properties.
function sGeboorteDatum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sGeboorteDatum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% Cancel
% --- Executes on button press in pCancel.
function pCancel_Callback(hObject, eventdata, handles)
% hObject    handle to pCancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

uiresume;

% --- Executes on selection change in popupmenu2.
function popupmenu2_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupmenu2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu2

% --- Executes during object creation, after setting all properties.
function popupmenu2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in sLaborant.
function sLaborant_Callback(hObject, eventdata, handles)
% hObject    handle to sLaborant (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns sLaborant contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sLaborant

% --- Executes during object creation, after setting all properties.
function sLaborant_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sLaborant (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in popLaborant.
function popLaborant_Callback(hObject, eventdata, handles)
% hObject    handle to popLaborant (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popLaborant contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popLaborant

% --- Executes during object creation, after setting all properties.
function popLaborant_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popLaborant (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in popKant.
function popKant_Callback(hObject, eventdata, handles)
% hObject    handle to popKant (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popKant contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popKant


% --- Executes during object creation, after setting all properties.
function popKant_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popKant (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
set(hObject,'val',3);


%% Own functions
function val = getIndex(cellString, searchString, nrElements);
% getIndex searches the strings in cellstring for  searchString, returning
% the index value at wich the string matches
%
% Val:          index of matching cell, index of dropdownbox string 
% celstring:    cell string with the dropdownbox strings
% searchstring: String wich indexvalue needs to be found
% nrElements:   Number of elemnts in the dropdownbox
for i=1:nrElements;
    if strcmp(cellString(i),searchString)==1; 
        val = i;
        break;
    end;
end;

% --- Executes on button press in pOK.
function pOK_Callback(hObject, eventdata, handles)
% hObject    handle to pOK (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%% Create output struct and send it on OK event
%r.patient.patientid     = str2double(get(handles.sPatNr, 'string')); 
r.patient.patientid     = get(handles.sPatNr, 'string'); 
r.patient.name          = get(handles.sName, 'string'); 
r.patient.geboortedatum = get(handles.sGeboorteDatum, 'string');
r.patient.lengte        = str2double(rmcomma(get(handles.sLengte, 'string')));
r.patient.gewicht       = str2double(rmcomma(get(handles.sGewicht, 'string')));
r.patient.geslacht      = get(handles.sGeslacht, 'string');
r.patient.leeftijd      = str2double(rmcomma(get(handles.sLeeftijd, 'string')));
r.patient.meetdatum     = get(handles.sMeetDatum, 'string');
if strcmp(get(handles.popLaborant,'style'),'popupmenu')
    val = get(handles.popLaborant,'value');
    string_list=get(handles.popLaborant,'string');
    r.laborant.naam = string_list{val};
else
    r.laborant.naam         = get(handles.popLaborant,'String');
end;
val = get(handles.popKant,'Value');
string_list = get(handles.popKant,'String');
r.patient.kant = string_list{val}; 

if isnan(r.patient.lengte) || isnan(r.patient.gewicht)...
         || isempty(r.patient.geslacht) || isempty(r.patient.leeftijd)
     errordlg('Error: please note that length, weight, sex and age must have valid values','Error','modal');
     return;
end;

% val = get(handles.popLaborant,'Value');
% string_list = get(handles.popLaborant,'String');
% r.laborant.naam = string_list{val}; 

set(gcf,'userdata',r);
uiresume(gcf);

function chkinput(varargin)

if (~isempty(varargin{1}) && isnan(str2double(varargin{1})))
    if nargin ==2
        uicontrol(varargin{2});
    end
    errordlg({'Fout in het ingevoerde getal'},'Foutieve invoer');
end

% --- Executes on button press in edit.
function edit_Callback(hObject, eventdata, handles)
% hObject    handle to edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
enable_edit(handles);

function enable_edit(handles)

    set(handles.sPatNr,'Enable','on');
    set(handles.sPatNr,'backgroundcolor',[1 1 1]);
    set(handles.sPatNr,'foregroundcolor',[0 0 0]);
    set(handles.sName,'Enable','on');
    set(handles.sName,'backgroundcolor',[1 1 1]);
    set(handles.sName,'foregroundcolor',[0 0 0]);
    set(handles.sGeboorteDatum,'Enable','on');
    set(handles.sGeboorteDatum,'backgroundcolor',[1 1 1]);
    set(handles.sGeboorteDatum,'foregroundcolor',[0 0 0]);
    set(handles.sLengte,'Enable','on');
    set(handles.sLengte,'backgroundcolor',[1 1 1]);
    set(handles.sLengte,'foregroundcolor',[0 0 0]);
    set(handles.sGeslacht,'Enable','on');
    set(handles.sGeslacht,'backgroundcolor',[1 1 1]);
    set(handles.sGeslacht,'foregroundcolor',[0 0 0]);
%     set(handles.sLeeftijd,'Enable','on');
%     set(handles.sLeeftijd,'backgroundcolor',[1 1 1]);
%     set(handles.sLeeftijd,'foregroundcolor',[0 0 0]);
    set(handles.sMeetDatum,'Enable','on');
    set(handles.sMeetDatum,'backgroundcolor',[1 1 1]);
    set(handles.sMeetDatum,'foregroundcolor',[0 0 0]);
    set(handles.popLaborant,'Enable','on');



function sName_Callback(hObject, eventdata, handles)
% hObject    handle to sName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sName as text
%        str2double(get(hObject,'String')) returns contents of sName as a double


% --- Executes during object creation, after setting all properties.
function sName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
%delete(hObject);
uiresume;

