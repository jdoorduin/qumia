function varargout = qumia(varargin)
% QUMIA program for ROI analysis of ultrasound muscle images
% Usage:QUMIA  or
%       QUMIA(0,folder, patientnr, birthdate, gender, laborant)
%       folder should contain the path and folder in which the images are located
% The program will create a new folder called ROI in which the ROI data is
% stored. See for further details the manual of the program.

% (c) Radboudumc, Nijmegen, Netherlands, by H. van Dijk / G. Weijers / J. Doorduin
% Version 3.0, Date: 2017/12/06

%   CAUS Core integrated into QUMIA by MUSIC, Radiology (G.Weijers)
%   - QA4US calibration and relative gray-level expression to ATS-550 Multipurpose Tissue Mimicking Phantom
%   - Fat-layer Attenuation correction
%   - Beam-profile correction
%   - Axial and Lateral speckle size estimation
%   - Musclelist (freq - rare) & musclename addition
%
% Installed MCR on KNF PC's > V82 > Matlab2013b

% Begin initialization code - DO NOT EDIT

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @qumia_OpeningFcn, ...
    'gui_OutputFcn',  @qumia_OutputFcn, ...
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


% --- Executes just before qumia is made visible.
function qumia_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to qumia (see VARARGIN)

% Choose default command line output for qumia
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% QUMIA revision string
ud.qumiaversion='Version 3.0';
set(handles.figure1,'name','QUMIA 3.0')

if ~isempty(varargin)&&length(varargin)~=6
    msgbox(['Not enough input arguments' ' Narg = ' num2str(length(varargin))]);
end

if exist('qumia_config_path.ini','file')
    fid=fopen('qumia_config_path.ini');
    ud.qumia_path=inigetvalue(fid,'PATH','qumia_config_path',[]);
    fclose(fid);
else
    ud.qumia_path = uigetdir(cd,'Select folder with qumia configuration');
    fid_new = fopen(fullfile(cd,'qumia_config_path.ini'),'wt');
    fprintf(fid_new,'%s\n','[PATH]');
    fprintf(fid_new,'%s','qumia_config_path=');
    fprintf(fid_new,'%s',ud.qumia_path);
    fclose(fid_new);
end

fid=fopen(fullfile(ud.qumia_path,'qumia.ini'));
ud.saveas=inigetvalue(fid,'FILE','saveas',[]);
ud.template=inigetvalue(fid,'FILE','template',[]);

if isempty(varargin)
    
    ud.path=0;
    ud.defaultpath=inigetvalue(fid,'FILE','input_path',[]);
    ud.output_path=inigetvalue(fid,'FILE','output_path',[]);
    
    %% PROJECTSETTINGS
    ud.projectsfile=fullfile(ud.qumia_path,inigetvalue(fid,'FILE','projectsettings',[]));
    if ud.projectsfile==0
        ud.projectsfile='';
        uiwait(msgbox({...
            'no projectsettings filepath defined in qumia.ini',...
            ' 1 - Please create and define projectsettings field and value in QUMIA.ini'}))
        return
    elseif ~exist(ud.projectsfile,'file')
        ud.projectsfile='';
        uiwait(msgbox({['non existings projectsettings filepath [',ud.projectsfile,'] defined in qumia.ini'],...
            '1 - Point the correct location of the projectsettings.txt file in qumia.ini.','2 - restart QUMIA.'}))
    else
        % Show projects in selector and put projectsetting into ud structure
        ud.ProjectSettings = LoadProjectSettings(ud.projectsfile,ud.qumia_path);
        Projects = ud.ProjectSettings.Project;
        value = 1; % TO BE AUTO(RE)LOADED BASED ON STORED (PREVIOUSLY USED) SETTINGS
        set(handles.ProjectSelect,'String',Projects,'value',value)
    end
    
    
    %% MUSCLELIST
    ud.musclelist=fullfile(ud.qumia_path,inigetvalue(fid,'FILE','musclelist',[]));
    if ud.musclelist==0
        return
    elseif ~exist(ud.musclelist,'file') % First time load muslestruct
        uiwait(msgbox('Muscle list has to be defined in the qumia.ini'));
        return
    else % load  muscle_data
        
        [muscle_list] = load_excel_musclelist(ud.musclelist);
        
        [ud.sorted_list] = sort_muscle_list(muscle_list.names,muscle_list.state);
        ud.musclestruct.name = muscle_list.names;
        ud.musclestruct.key = muscle_list.keys;
        ud.musclestruct.state = muscle_list.state;
        ud.musclestruct.posFL = muscle_list.posFL;
        ud.musclestruct.posFR = muscle_list.posFR;
        ud.musclestruct.posBL= muscle_list.posBL;
        ud.musclestruct.posBR = muscle_list.posBR;
        
        ud.current_muscle.musclekey = ud.musclestruct.key(1);
        ud.current_muscle.muscle = ud.musclestruct.name{1};
        ud.current_muscle.musclestate =  ud.musclestruct.state(1);
        
        set(findobj('Tag','MuscleList'),'String',ud.sorted_list,'Value',1)
    end
    %% MUSCLE MODELS
    
    ud.musclemodels=fullfile(ud.qumia_path,inigetvalue(fid,'FILE','musclemodels',[]));
    ud.musclestruct.model.modelnr_thickness=str2double(inigetvalue(fid,'FILE','modelnr_thickness',[]));
    ud.musclestruct.model.modelnr_ei=str2double(inigetvalue(fid,'FILE','modelnr_ei',[]));
    
    if ud.musclelist==0
        return
    elseif ~exist(ud.musclelist,'file') % First time load muslestruct
        uiwait(msgbox('Muscle list has to be defined in the qumia.ini'));
        return
    else % load  models
        
        load(ud.musclemodels);
        
        if exist('mdls_thickness','var')
            ud.musclestruct.model.thickness = mdls_thickness;
            ud.musclestruct.thick_ref_check = 1;
        else
            ud.musclestruct.model.thickness = {};
            ud.musclestruct.thick_ref_check = 0;
        end
        if exist('mdls_EI','var')
            ud.musclestruct.model.ei = mdls_EI;
            ud.musclestruct.EI_ref_check = 1;
        else
            ud.musclestruct.model.ei = {};
            ud.musclestruct.EI_ref_check = 0;
        end
    end
    
    if ud.musclestruct.EI_ref_check==0 && ud.musclestruct.thick_ref_check==0
        set(handles.genreport,'Enable','Off','Visible','Off')
        set(handles.SupportFig,'Enable','Off','Visible','Off')
    end
    
end
fclose(fid);

%% 2013-07-24 GW: added for enabling support/develop figures/lines
set(handles.SupportFig,'value',0);
ud.autolines.SupportFig=0;
ud.autolines.SupportLine=0;

ud.autolines.at=[];
ud.autolines.currentfile=0;
ud.autolines.calip.cnt=[];
ud.autolines.calip.markers=['+';'x';'*';'o';'s';'d';'v';'^';'<';'>';'p';'h'];
ud.autolines.calip.visible='on';
ud.current_muscle.side ='L';

ud.autolines.reportfilenr=0;
set(handles.figure1,'paperpositionMode','auto')
ud.autolines.framegrabber=0;

ud.vector_handles = [handles.MuscleList handles.ProjectSelect handles.links handles.rechts handles.ROI handles.spierdikte ...
    handles.fasciculaties handles.patientdata handles.btn_SupportLines handles.SupportFig handles.Next ...
    handles.Previous handles.annotation_bar handles.caliper ...
    handles.genreport handles.saveresults handles.Echo_ContextMenu_RemoveRoi handles.delete_musclesize ...
    handles.DeleteCalipers handles.delete_annotation handles.hist handles.annotation_toolbar handles.caliper_toolbar];
set(ud.vector_handles,'Enable','Off')

set(handles.figure1,'userdata',ud);


% --- Outputs from this function are returned to the command line.
function varargout = qumia_OutputFcn(hObject, eventdata, handles)  %#ok<*INUSL>
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
ud=get(handles.figure1,'userdata');
if isempty(ud)
    delete(handles.figure1);
    varargout{1}=[];
    return;
end;
varargout{1} = handles.output;

% EDIT MENU------------------------------------------------
% function Untitled_2_Callback(hObject, eventdata, handles)
% % hObject    handle to Edit (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in Next.
function Next_Callback(hObject, eventdata, handles) %#ok<*DEFNU>
% hObject    handle to Next (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ud = get(handles.figure1,'userdata');
ud = nextfile(ud,handles);
set(handles.figure1,'userdata',ud);


% --- Executes on button press in Previous.
function Previous_Callback(hObject, eventdata, handles)
% hObject    handle to Previous (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ud = get(handles.figure1,'userdata');
ud = previousfile(ud,handles);
set(handles.figure1,'userdata',ud);

% --- Executes when figure1 is resized.
function figure1_ResizeFcn(hObject, eventdata, handles) %#ok<*INUSD>
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in links.
function links_Callback(hObject, eventdata, handles)
% hObject    handle to links (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ud = get(handles.figure1,'userdata');
ud.current_muscle.side  = 'L';
if diameter_alreadyset(ud)
    set(hObject,'Value',0);
    return;
end;
set(hObject,'Value',1);
set(handles.rechts,'value',0);
ud.analyzed_muscles.sides{ud.autolines.currentfile}='L';
ud.analyzed_muscles.muscles{ud.autolines.currentfile}=ud.current_muscle.muscle;
ud.analyzed_muscles.musclekeys{ud.autolines.currentfile}=ud.current_muscle.musclekey;
set(handles.figure1,'userdata',ud);

%set(handles.links,'ForeGroundColor',[0, 0, 0])
%set(handles.rechts,'ForeGroundColor',[0, 0, 0])
updatetitle(ud);

% --- Executes on button press in rechts.
function rechts_Callback(hObject, eventdata, handles)
% hObject    handle to rechts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ud = get(handles.figure1,'userdata');
ud.current_muscle.side  = 'R';

if diameter_alreadyset(ud)
    set(hObject,'Value',0);
    return;
end;
set(hObject,'Value',1);
set(handles.links,'value',0);
ud.analyzed_muscles.sides{ud.autolines.currentfile}='R';
ud.analyzed_muscles.muscles{ud.autolines.currentfile}=ud.current_muscle.muscle;
ud.analyzed_muscles.musclekeys{ud.autolines.currentfile}=ud.current_muscle.musclekey;
set(handles.figure1,'userdata',ud);
updatetitle(ud);

% --------------------------------------------------------------------
function Open_Callback(hObject, eventdata, handles)
% hObject    handle to Open (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

open_dir(handles);

function open_dir(handles,noui)

ud=get(handles.figure1,'userdata');

ud.current_muscle.cal = []; % empty calibration
ud.current_muscle.roi = []; % empty auto located ROI
%ud.reportimage = {};

if nargin<2
    % open directory
    ud.path=uigetdir(ud.defaultpath);
end;

if ud.path==0
    return;
end;

%try
loadfiles(ud,handles)
%catch ME
%   errordlg(ME.message,'QUMIA error');
%    return;
%end;

ud=get(handles.figure1,'userdata');
if isfield(ud,'resultstruct')
    ud=rmfield(ud,'resultstruct');
end;

if ~isempty(ud.laborant)
    lab = ud.laborant.naam;
else
    lab = '';
end

if isempty(ud.patient)
    pat=patData(ud.dcminfo,lab);
else
    p.patient=ud.patient;
    p.laborant=ud.laborant;
    pat=patData(p,1);
end;

if ~isempty(pat)
    ud.patient=pat.patient;
    ud.laborant=pat.laborant;
end;

set(ud.vector_handles,'Enable','On')
set(handles.figure1,'userdata',ud);

%% Loadfiles
% --------------------------------------------------------------------
function loadfiles(ud,handles)

% read all dicom files and sort them
dcmdir=getdicomfiles(ud.path);
if isempty(dcmdir)
    error('No dicom files were found in the selected folder');
end;

ud.analyzed_muscles.dcmfiles=[];

ud.analyzed_muscles.timedate=[];
for i=1:length(dcmdir)
    dcmfiles{i}=dcmdir(i).name; %#ok<*AGROW>
    timedate{i}=dcmdir(i).date; %#ok<*NASGU>
end;

% now sort based on filenumber if applicable
if not(isempty([dcmdir.filenr]))
    [tmp,idx]=sort([dcmdir.filenr]);
else
    idx=1:length({dcmdir.name});
end
ud.analyzed_muscles.dcmfiles=dcmfiles(idx);

ud.autolines.currentfile=0;
ud.analyzed_muscles.meanroi=[];
if isfield(ud.autolines,'calip')
    ud.autolines=rmfield(ud.autolines,'calip');
end;
ud.autolines.calip.cnt=[];
ud.autolines.calip.markers=['+';'x';'*';'o';'s';'d';'v';'^';'<';'>';'p';'h'];
ud.autolines.calip.visible='on';
[success,msg]=mkdir(ud.path,'roi');
if success~=1
    errordlg(msg,'Error');
end;
nfiles=length(ud.analyzed_muscles.dcmfiles);
ud.storepath=fullfile(ud.path,'roi');
ud.analyzed_muscles.roihndl=[];
ud.analyzed_muscles.rois=cell(nfiles,1);
ud.analyzed_muscles.musclediam=zeros(nfiles,1);
ud.analyzed_muscles.fatlayer=zeros(nfiles,1);
ud.analyzed_muscles.meanroi=zeros(nfiles,1);
ud.analyzed_muscles.sides=cell(nfiles,1);
ud.analyzed_muscles.muscles=cell(nfiles,1);
ud.analyzed_muscles.musclekeys=cell(nfiles,1);
ud.analyzed_muscles.normset=zeros(nfiles,1);
ud.autolines.framegrabber=0; % make sure framegrabber is reset

% NEW variables added: 203-07-24, by GW: MUSIC
ud.analyzed_muscles.meanroi_rel_dB = NaN(nfiles,1);          % 2013-08-08 GW: caus AVG mu
ud.analyzed_muscles.corrections = zeros(nfiles,5);           % 2013-08-08 GW: caus corrections applied
ud.analyzed_muscles.Project = cell(nfiles,1);                % 2013-07-31 GW: used project settings for CAUS corrections
ud.analyzed_muscles.SpAx = NaN(nfiles,1);                    % 2013-07-24 GW: Axial speckle size results
ud.analyzed_muscles.SpLat = NaN(nfiles,1);                   % 2013-07-24 GW: Lateral speckle size results
ud.analyzed_muscles.SpMethod = cell(nfiles,1);               % 2013-07-24 GW: Method for speckle size estimation
ud.analyzed_muscles.fatcontour = cell(nfiles,1);             % 2013-07-24 GW: pointed fatlayer contours
ud.analyzed_muscles.AvgFatThick = NaN(nfiles,1);             % 2013-07-24 GW: avg fatlayer thicknesses

% reset tmp variables (to be removed!!!)
ud.current_muscle.muscle_image_cor = [];                                 % 2013-07-24 GW: CAUS corrected image
ud.current_muscle.FatMask = [];                            % 2013-07-24 GW:
ud.current_muscle.roi = [];
ud.current_muscle.cal = [];

% set slider
set(handles.slider1,'max',nfiles);
set(handles.slider1,'min',1);
set(handles.slider1,'sliderstep',[1/nfiles round(nfiles/10)/nfiles]);
set(handles.slider1,'value',1);

if isfield(ud.analyzed_muscles,'fasc')
    ud.analyzed_muscles=rmfield(ud.analyzed_muscles,'fasc');
end;
ud.patient=[];
ud.laborant=[];
if exist(fullfile(ud.path,'roi','anal.mat'),'file')
    load(fullfile(ud.path,'roi','anal.mat'));
    
    % Check the dicom fileslist
    if length(dcmfiles)> length(ud.analyzed_muscles.dcmfiles)
        uiwait(warndlg(sprintf('Number of dicom files in folder changed!\nA file has been removed\n\nOld ROIs not usable\nDraw new ROIs'),'Warning','modal'));
        
    elseif length(dcmfiles) < length(ud.analyzed_muscles.dcmfiles)
        result = strcmp(dcmfiles,ud.analyzed_muscles.dcmfiles(1:length(dcmfiles)));
        
        uiwait(warndlg(sprintf('Number of dicom files in folder changed!\nA file has been added\n\nOld ROIs not usable\nDraw new ROIs'),'Warning','modal'));
        
    elseif(length(dcmfiles) == length(ud.analyzed_muscles.dcmfiles))
        result = strcmp(dcmfiles,ud.analyzed_muscles.dcmfiles);
        if(~isempty(find(result~=1, 1)))
            uiwait(warndlg(sprintf('Number of dicom files in folder changed!\nThe file order has changed\n\nOld ROIs not usable\nDraw new ROIs'),'Warning','modal'));
            keyboard
        else
            % Nothing changed, use anal.mat values
            ud.analyzed_muscles.rois=rois;
            ud.analyzed_muscles.musclediam=musclediam;
            ud.analyzed_muscles.fatlayer=fatlayer;
            ud.analyzed_muscles.meanroi(1:length(meanroi))=meanroi;
            ud.analyzed_muscles.sides=sides;
            ud.analyzed_muscles.muscles=muscles;
            
            %% New CAUS parameters: 2013-07-29 GW
            ud.analyzed_muscles.Project = Project;               % used project settings per image (depth variation)
            ud.analyzed_muscles.fatcontour = fatcontour;         % Interactive selected muscle border
            ud.analyzed_muscles.corrections = corrections;
            ud.analyzed_muscles.SpAx = SpAx;                     % not crucial: can be recalculated...
            ud.analyzed_muscles.SpLat = SpLat;                   % not crucial: can be recalculated...
            ud.analyzed_muscles.AvgFatThick = AvgFatThick;       % not crucial: can be recalculated...
            
            ud.analyzed_muscles.musclekeys=musclekeys;
            ud.current_muscle.musclekey=ud.analyzed_muscles.musclekeys{1};
            if exist('normset','var')
                ud.analyzed_muscles.normset=normset;
            end;
        end
    end
    
    if exist('calip','var')
        ud.autolines.calip=calip;
        ud.autolines.calip.visible='on';
        ud.autolines.calip.markers=['+';'x';'*';'o';'s';'d';'v';'^';'<';'>';'p';'h'];
    end;
    
    if exist('at','var')
        ud.autolines.at=at;
    end
    
    if exist('reportimage','var')
        ud.reportimage=reportimage;
    end
    
    if ~isempty(fasc)
        ud.analyzed_muscles.fasc=fasc;
    end;
    ud.patient=patient;
    if isfield(patient,'radboudnr')
        ud.patient.patientid=patient.radboudnr;
    end;
    ud.laborant=laborant;
    if exist('musclenamelist','var')
        ud.musclenamelist = musclenamelist;
    end
end;
%set(handles.figure1,'name',['Quantitative muscle image analysis: ',ud.path])

set(handles.figure1,'userdata',ud);
ud=nextfile(ud,handles);
set(handles.figure1,'userdata',ud);

% --------------------------------------------------------------------
function Quit_Callback(hObject, eventdata, handles)
% hObject    handle to Quit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
answr = questdlg('Close QUMIA?','','Yes','Cancel','Cancel');
if strcmp(answr, 'Yes');
    close all
end

% --------------------------------------------------------------------
function Print_Callback(hObject, eventdata, handles)
% hObject    handle to Print (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
printdlg(handles.figure1);

% --------------------------------------------------------------------
function Saveas_Callback(hObject, eventdata, handles)
% hObject    handle to Saveas (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in ROI.
function ROI_Callback(hObject, eventdata, handles)
% hObject    handle to ROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%try
ud=get(handles.figure1,'userdata');
set(ud.vector_handles,'Enable','Off')
%     disablecontrols('off',handles); %

% Show original Image data first
cla; imagesc(ud.current_muscle.muscle_image); colormap(gray)
set(gca,'CLim',[0 max(ud.current_muscle.muscle_image(:))])
axis off; axis tight; zoom off;
set(gca,'dataaspectratio',[1 1 1]);

set(handles.figure1,'pointer','hand')

% display tissue border if pressent
if ~isempty(ud.analyzed_muscles.fatcontour{ud.autolines.currentfile})
    fat = ud.analyzed_muscles.fatcontour{ud.autolines.currentfile};
    plot(fat(:,1),fat(:,2),':c','LineWidth',2,'tag','fatcontour')
    %         ShowFatcontour(ud);
end

[roi,h] = roifreeselection([],handles.figure1);
set(handles.figure1,'pointer','arrow');

% GW resize to large roi and reduce ROI to defined limits
[sector dcm_roi roi_red]= ROIdetect(ud.current_muscle.muscle_image,ud.current_muscle.cal,ud.autolines.SupportFig);
roi = ReduceROI(roi,roi_red);
ud.analyzed_muscles.rois{ud.autolines.currentfile}=roi;

set(handles.ROI,'ForeGroundColor',[0, 0, 0])

ud.analyzed_muscles.roihndl=h;

filename=fullfile(ud.path,ud.analyzed_muscles.dcmfiles{ud.autolines.currentfile});

% save ROI to file including musclename and side
try
    if ~isempty(roi)
        side=ud.current_muscle.side ;
        muscle=ud.current_muscle.muscle;
        musclekey=ud.current_muscle.musclekey;
        
        save(fullfile(ud.storepath,[ud.analyzed_muscles.dcmfiles{ud.autolines.currentfile},'.mat']),'roi','side','muscle','musclekey');
        
        ud = displayimage(ud,handles); % Update results on screen
        
        if isempty(ud.Iconv) && isempty(ud.Iroi)
            ud.analyzed_muscles.rois{ud.autolines.currentfile}=[];
        end;
        ud.analyzed_muscles.sides{ud.autolines.currentfile}=side;
        ud.analyzed_muscles.muscles{ud.autolines.currentfile}=muscle;
        ud.analyzed_muscles.musclekeys{ud.autolines.currentfile}=musclekey;
        set(handles.figure1,'userdata',ud);
    else
        error('empty roi')
    end;
catch ME
    %         error(ME.message)
    % Set original echo data and ROI
    ud=get(handles.figure1,'userdata');
    if ~isempty(ud.analyzed_muscles.rois{ud.autolines.currentfile}) || (ud.analyzed_muscles.musclediam(ud.autolines.currentfile)~=0)
        if ~isempty(ud.analyzed_muscles.rois{ud.autolines.currentfile})
            x=[ud.analyzed_muscles.rois{ud.autolines.currentfile}(1,:) ud.analyzed_muscles.rois{ud.autolines.currentfile}(1,1)];
            y=[ud.analyzed_muscles.rois{ud.autolines.currentfile}(2,:) ud.analyzed_muscles.rois{ud.autolines.currentfile}(2,1)];
            ud.analyzed_muscles.roihndl=plot(x,y,'r-.');
        end;
        ud=setmuscleselection(ud,handles);
    end;
    set(handles.figure1,'userdata',ud);
    disp(ME.message) % GW 2013-07-24
end

[dummy,name,ext] = fileparts(ud.analyzed_muscles.dcmfiles{ud.autolines.currentfile});              % GW
filename = fullfile(ud.path,[name,'.tif']);                             % GW filename without extension

movegui(gcf)
f=getframe; % 2013-07-24 GW: Doesn't work on second monitor...
if ~isempty(f.colormap)
    imwrite(f.cdata,f.colormap,filename,'tiff','Compression','lzw');
else
    imwrite(f.cdata,filename,'tiff','Compression','lzw');
end
updatetitle(ud);
%ud.reportimage{ud.autolines.currentfile} = filename;
set(handles.figure1,'userdata',ud);

save_results(handles.figure1,'mid_result');

set(ud.vector_handles,'Enable','On')






% -------------------------------------------------------------------------
% GET CALIBRATION INFO FROM DICOM FILE
% GW, MUSIC: added 2013-07-23 (g.weijers@rad.umcn.nl)
function cal = GetDcmCalInfo(inf)
cal = [];
if isfield(inf,'SequenceOfUltrasoundRegions')
    if isfield(inf.SequenceOfUltrasoundRegions,'Item_1')
        if isfield(inf.SequenceOfUltrasoundRegions.Item_1,'PhysicalDeltaY')
            if inf.SequenceOfUltrasoundRegions.Item_1.PhysicalDeltaY ~= 0
                cal = inf.SequenceOfUltrasoundRegions.Item_1;
            end
        end
    end
end
% if isempty(cal)
%     uiwait(msgbox({...
%         'DICOM-field: "SequenceOfUltrasoundRegions" not found in DICOM header!',...
%         'Please check dicom export settings!!!'}))
%     return
% end

% -------------------------------------------------------------------------
% SPECKLE SIZE ESTIMATION
% GW, MUSIC: added 2013-07-24 (g.weijers@rad.umcn.nl)
%
% !!!! Gamma parameters needs to be included in calibration info
% (mat-files) !!!!
%
% function [SpAx,SpLat,method] = Speckle_Size_Estimation(ud)
%
% filename=fullfile(ud.path,ud.analyzed_muscles.dcmfiles{ud.autolines.currentfile});
%
% gamma = 4;                                      % !!! To be specified in project/equipment setting !!!
%
% if ~isfield(ud.current_muscle,'cal') || isempty(ud.current_muscle.cal)
%     ud.current_muscle.cal = GetDcmCalInfo(ud.dcminfo);         % Get calibration from dcm file
% end
% Store = 0;                                      % Store specklesize figure
% roi = ud.analyzed_muscles.rois{ud.autolines.currentfile};
% ROI = roipoly(ud.current_muscle.muscle_image,roi(1,:),roi(2,:));
% [SpAx,SpLat,method] = SpecklesizeAvgEstimate(ud.current_muscle.muscle_image,ROI,gamma,ud.current_muscle.cal.PhysicalDeltaX,ud.current_muscle.cal.PhysicalDeltaY,ud.autolines.SupportFig);
%
% disp('Speckle Size estimation module: 2013-07-23 (MUSIC, GW)')
% disp(sprintf(' --> Axial: %2.3f [mm]; Lateral: %2.3f [mm] (%s)',SpAx,SpLat,method))

% figure(handles.figure1) % swith back to qumia GUI

%% Previous file
function [ud,err]=previousfile(ud,handles)

ud.map = [];
ud.current_muscle.muscle_image_cor = []; ud.current_muscle.FatMask = []; % Delete temp FAT corrected image
ud.current_muscle.cal = []; ud.current_muscle.roi = [];
err=0;
if ~isfield(ud.analyzed_muscles,'dcmfiles')
    return;
end;
if ud.autolines.currentfile>1
    ud.autolines.currentfile=ud.autolines.currentfile-1;
else
    err=-1;
    return;
end;
[ud,err]= ReadFile(ud,handles);

%% Nextfile
function [ud,err]=nextfile(ud,handles)

ud.map = [];
ud.current_muscle.muscle_image_cor = []; ud.current_muscle.FatMask = []; % Delete temp FAT corrected image
ud.current_muscle.cal = []; ud.current_muscle.roi = [];
err=0;
if ~isfield(ud.analyzed_muscles,'dcmfiles')
    return;
end;
if ud.autolines.currentfile<length(ud.analyzed_muscles.dcmfiles)
    ud.autolines.currentfile=ud.autolines.currentfile+1;
else
    err=-1;
    return;
end;
[ud,err] = ReadFile(ud,handles);


%% ReadFile
function [ud,err]= ReadFile(ud,handles)

d=dir(fullfile(ud.path,ud.analyzed_muscles.dcmfiles{ud.autolines.currentfile}));
if d.bytes==0
    warndlg(['Filename: ',ud.analyzed_muscles.dcmfiles{ud.autolines.currentfile}],'Warning file size is 0','modal');
    uiwait;
end;

err=1;

%ud.dcminfo = [];
ud.dcminfo=dicominfo(fullfile(ud.path,ud.analyzed_muscles.dcmfiles{ud.autolines.currentfile}));

ismultiframe = isfield(ud.dcminfo,'NumberOfFrames') && ud.dcminfo.NumberOfFrames > 1; % works for esaote
if ismultiframe
    % ignore multiframe dicom
    return
end

if ~(d.bytes<6e6 && d.bytes > 0)
    disp('Invalid DICOM FILE: ''%s''',fullfile(ud.path,ud.analyzed_muscles.dcmfiles{ud.autolines.currentfile}))
    return
end

% determine machine
if isfield(ud.dcminfo,'ManufacturerModelName')
    ud.machine=upper(ud.dcminfo.ManufacturerModelName);
else
    ud.machine='';%
end;

% read Image
ud.current_muscle.muscle_image=dicomread(fullfile(ud.path,ud.analyzed_muscles.dcmfiles{ud.autolines.currentfile}));
if strcmp(ud.machine,'Z_ONE')
    if ndims(ud.current_muscle.muscle_image)==2
        map=double([ud.dcminfo.RedPaletteColorLookupTableData ud.dcminfo.GreenPaletteColorLookupTableData ud.dcminfo.BluePaletteColorLookupTableData])./2^16;
        ud.current_muscle.muscle_image=uint8(reshape(map(ud.current_muscle.muscle_image(:)+1,1)*255,size(ud.current_muscle.muscle_image)));
    end;
end;

% GW: Take a weighted combination of all colors (ROI data is unaffected
% since gr.lvl are same over alle RGB layers!!!
if ndims(ud.current_muscle.muscle_image)==3
    ud.current_muscle.muscle_image = double(.2989*ud.current_muscle.muscle_image(:,:,1)+.5870*ud.current_muscle.muscle_image(:,:,2)+.1140*ud.current_muscle.muscle_image(:,:,3));
end
set(handles.slider1,'value',length(ud.analyzed_muscles.dcmfiles)-ud.autolines.currentfile+1);
set(handles.filenr,'string',[num2str(ud.autolines.currentfile),' - ',num2str(length(ud.analyzed_muscles.dcmfiles))]);
set(handles.figure1,'userdata',ud);

ud.current_muscle.cal = GetDcmCalInfo(ud.dcminfo);
if ~isempty(ud.current_muscle.cal)
    [ud.current_muscle.roi, ud.dcm_roi, ud.roi_red]= ROIdetect(ud.current_muscle.muscle_image,ud.current_muscle.cal,ud.autolines.SupportFig);
end
ud = displayimage(ud,handles);


if strcmp(ud.analyzed_muscles.Project(ud.autolines.currentfile),'None')
    set(handles.SupportFig,'Enable','Off','Visible','Off')
else
    set(handles.SupportFig,'Enable','On','Visible','On')
end

function ud=recalcimage(ud)

% Check if ROI within limits (+/-15%) of sector data
if ~isempty(ud.analyzed_muscles.rois{ud.autolines.currentfile})
    ud.analyzed_muscles.rois{ud.autolines.currentfile} = ReduceROI(ud.analyzed_muscles.rois{ud.autolines.currentfile},ud.roi_red);
end
%     [ud.Iconv,ud.Iroi,ud.Icorr,res,ud.analyzed_muscles.fatcontour{ud.autolines.currentfile}] = convertimage_caus(ud.curProject,ud.current_muscle.muscle_image,ud.analyzed_muscles.rois{ud.autolines.currentfile},ud.current_muscle.roi,ud.roi_red,ud.analyzed_muscles.fatcontour{ud.autolines.currentfile},ud.current_muscle.cal,ud.autolines.SupportFig);

[ud.Iconv,ud.Iroi,ud.Icorr,res,ud.analyzed_muscles.fatcontour{ud.autolines.currentfile},ud.LUT2] = convertimage_caus(ud.qumia_path,ud.ProjectSettings,ud.curProject,ud.current_muscle.muscle_image,ud.analyzed_muscles.rois{ud.autolines.currentfile},ud.current_muscle.roi,ud.roi_red,ud.dcm_roi,ud.current_muscle.cal,ud.autolines.SupportFig);

ud.analyzed_muscles.AvgFatThick(ud.autolines.currentfile)      = res.AvgFatThick;
ud.analyzed_muscles.meanroi_rel_dB(ud.autolines.currentfile)   = res.meanroi_rel_dB;   % AVG echolevel [dB] relative to phantom 0dB
ud.analyzed_muscles.meanroi(ud.autolines.currentfile)          = res.meanroi;          % AVG echolevel [gr.lvl] original image
ud.analyzed_muscles.SpAx(ud.autolines.currentfile)             = res.SpAx;
ud.analyzed_muscles.SpLat(ud.autolines.currentfile)            = res.SpLat;
ud.analyzed_muscles.SpMethod{ud.autolines.currentfile}         = res.SpMethod;
ud.analyzed_muscles.corrections(ud.autolines.currentfile,:)    = res.c;                % (LUT(c=1), GAIN-GAMMA(c=2), BEAMPROFILE(normset=3), FAT_ATT(c=4), MU_REL_dB(c=5)


function ud=displayimage(ud,handles)
% displays image depending on machine

% Get/apply Project Settings/Info
if isempty(ud.autolines.currentfile)
    uiwait(msgbox('Open patient directory first before changing project settings!'))
    return
end

if isempty(ud.analyzed_muscles.Project{ud.autolines.currentfile}) % USE SELECTED PROJECT SETTINGS
    id = get(handles.ProjectSelect,'Value');
    Projects = get(handles.ProjectSelect,'String');
    Project = Projects{id};
    ud.analyzed_muscles.Project{ud.autolines.currentfile} = Project;
    ud.curProject = GetCurrentProjectSettings(ud.ProjectSettings,id);   % Get selected settings
    ud.curProject.id = id;
    %set(handles.txt_Projects,'ForeGroundColor',[0.08, 0.17, 0.5])
    %set(handles.ProjectSelect,'ForeGroundColor',[0.08, 0.17, 0.5])
    
else % Find the previous used projectsettings
    %set(handles.txt_Projects,'ForeGroundColor','k')
    %set(handles.ProjectSelect,'ForeGroundColor','k')
    prevProject = ud.analyzed_muscles.Project{ud.autolines.currentfile};
    prevProject = strrep(prevProject,'Easote','Esaote'); % GW: Was once wrong defined...
    Projects = get(handles.ProjectSelect,'String');
    curProject = Projects{get(handles.ProjectSelect,'value')};
    
    found=0;
    for n=1:length(Projects)
        if strcmp(Projects{n},prevProject)
            found = 1;
            break;
        end
    end
    if ~found
        set(handles.ProjectSelect,'ForeGroundColor','r')
        ud.curProject = '';
        ud.curProject.id = 1;
        uiwait(msgbox({['Preset/ProjectName: ',prevProject,' does not exist anymore!!!'],...
            'please choose correspoinding/renamed calibrated Preset name!'}))
    else
        ud.curProject = GetCurrentProjectSettings(ud.ProjectSettings,n); % Get previous settings
        ud.curProject.id = n;
        set(handles.ProjectSelect,'value',n)
    end
end

% Get previously selected muscle or last selected
if ~isempty(ud.analyzed_muscles.muscles{ud.autolines.currentfile})
    ud.current_muscle.muscle = ud.analyzed_muscles.muscles{ud.autolines.currentfile};
    
    show_musclelist(ud)                         % Show list
    
    %set(handles.txt_musclelist,'ForeGroundColor',[0, 0, 0])
    set(handles.MuscleList,'ForeGroundColor',[0, 0, 0])
else
    List = get(handles.MuscleList,'String');
    ud.analyzed_muscles.muscles{ud.autolines.currentfile} = List{get(handles.MuscleList,'Value')};
    ud.current_muscle.muscle = ud.analyzed_muscles.muscles{ud.autolines.currentfile};
    %set(handles.txt_musclelist,'ForeGroundColor',[0.08, 0.17, 0.5])
    set(handles.MuscleList,'ForeGroundColor',[0.08, 0.17, 0.5])
end

% Get previously or last selected side
side = ud.analyzed_muscles.sides{ud.autolines.currentfile};
if isempty(side)
    if get(findobj('Tag','links'),'Value')
        ud.analyzed_muscles.sides{ud.autolines.currentfile} = 'L';
        ud.current_muscle.side  = 'L';
    else
        ud.analyzed_muscles.sides{ud.autolines.currentfile} = 'R';
        ud.current_muscle.side  = 'R';
    end
    %set(handles.links,'ForeGroundColor',[0.08, 0.17, 0.5])
    %set(handles.rechts,'ForeGroundColor',[0.08, 0.17, 0.5])
else
    ud.current_muscle.side  = side;
    if strcmp(side,'R')
        set(handles.links,'Value',0);
        set(handles.rechts,'value',1);
    else
        set(handles.links,'Value',1);
        set(handles.rechts,'value',0);
    end
    %set(handles.links,'ForeGroundColor',[0, 0, 0])
    %set(handles.rechts,'ForeGroundColor',[0, 0, 0])
end

% init pointer and calibrations
p = ud.autolines.currentfile;
% ud.current_muscle.cal = GetDcmCalInfo(ud.dcminfo);

if ~isempty(ud.current_muscle.cal)
    [ud.current_muscle.roi, ud.dcm_roi, ud.roi_red]= ROIdetect(ud.current_muscle.muscle_image,ud.current_muscle.cal,ud.autolines.SupportFig);
    
    ud = recalcimage(ud); % APPLY CAUS CORRECTIONS
    
    % Show results
    if ud.autolines.SupportLine
        I = ud.Icorr;  % Corrected image (LUT,FAT,ATT) in gr.lvl
    else I = ud.current_muscle.muscle_image;      % Original image without corrections
    end
else
    I = ud.current_muscle.muscle_image; % No valid dicom file
end

cla;
imagesc(I)
colormap(gray)
cl = get(gca,'CLim');
if exist('Iconv','var')
    clim_max = max(Iconv);
else clim_max = max(I(:));
end
set(gca,'CLim',[0 clim_max])

% ud.map=gray(256);
%warndlg('Unkonwn machine type. Image may not be displayed correctly');
% if ~isempty(ud.map), colormap(ud.map); end
axis off;
axis tight;
updatetitle(ud)
set(gca,'dataaspectratio',[1 1 1]);
h1=get(gca,'children');
set(h1,'uiContextMenu',handles.Echo_ContextMenu);
%set(h1,'ButtonDownFcn','qumia(''imagebuttondown'',gcbo,[],guidata(gcbo))');
hold on;
ud.analyzed_muscles.roihndl=[];

% Show DICOM ROI(yellow) and detected ROI data (red)
if ~isempty(ud.current_muscle.cal) % valid dicom cal
    [roi dcm_roi roi_red] = ROIdetect(ud.current_muscle.muscle_image,ud.current_muscle.cal,ud.autolines.SupportLine);
    
    % Show previous ROI
    if ~isempty(ud.analyzed_muscles.rois{p}) || (ud.analyzed_muscles.musclediam(p)~=0)
        if ~isempty(ud.analyzed_muscles.rois{p})
            x=[ud.analyzed_muscles.rois{p}(1,:) ud.analyzed_muscles.rois{p}(1,1)];
            y=[ud.analyzed_muscles.rois{p}(2,:) ud.analyzed_muscles.rois{p}(2,1)];
            ud.analyzed_muscles.roihndl=plot(x,y,'g-.','LineWidth',2);
        end;
        %     disp(ud.autolines.currentfile)
        ud=setmuscleselection(ud, handles);
        set(handles.ROI,'ForeGroundColor',[0, 0, 0])
    else
        set(handles.ROI,'ForeGroundColor',[0.08, 0.17, 0.5])
    end
    
    % Show LUT
    if ud.autolines.SupportLine
        PS = ud.curProject;
        if isfield(ud,'LUT2') && ~isempty(ud.LUT2)
            load(char(ud.LUT2))
            plot(x,y,':m','Tag','LUT')
        elseif isfield(PS,'LUTposFLoc') && ~isempty(char(PS.LUTposFLoc)) && exist(char(PS.LUTposFLoc),'file')
            load(char(PS.LUTposFLoc))
            plot(x,y,'y','Tag','LUT')
        end
    end
    
    % Show fat contour if pressent
    if isfield(ud.analyzed_muscles,'fatcontour') && ~isempty(ud.analyzed_muscles.fatcontour{ud.autolines.currentfile})
        fat = ud.analyzed_muscles.fatcontour{ud.autolines.currentfile};
        plot(fat(:,1),fat(:,2),':c','LineWidth',2,'tag','fatcontour')
        set(handles.Fatlayer,'ForeGroundColor',[0,0,0])
    else
        set(handles.Fatlayer,'ForeGroundColor',[0.08, 0.17, 0.5])
    end
    
    % plot calipers if included
    ud = plotcalipers(ud);
    PS = ud.curProject;
    
    % plot annotations if included
    if ~isempty(ud.autolines.at)
        if ud.autolines.currentfile<=length(ud.autolines.at)
            if isfield(ud.autolines.at{ud.autolines.currentfile},'text')
                for i=1:length(ud.autolines.at{ud.autolines.currentfile}.text);
                    x_text = ud.autolines.at{ud.autolines.currentfile}.pos{i}(1);
                    y_text = ud.autolines.at{ud.autolines.currentfile}.pos{i}(2);
                    annotation = ud.autolines.at{ud.autolines.currentfile}.text{i};
                    h_text = text(x_text,y_text,annotation);
                    set(h_text,'color','y');
                end
            end
        end
    end
    
    
    if ~isempty(PS)
        % DISPLAY RESULTS ONSCREEN
        delete(findobj('Tag','Values')) % Delete previous results
        if isfield(ud.analyzed_muscles,'meanroi_rel_dB') && ~isempty(ud.analyzed_muscles.meanroi_rel_dB)
            MuCAUSdB = sprintf('Corr. echo int.: %3.2f [dB]',ud.analyzed_muscles.meanroi_rel_dB(p));
            MuCAUSgray = sprintf('Corr. echo int.: %3.2f [gr.lvl]',ud.analyzed_muscles.meanroi_rel_dB(p)*3.8+48.7);
        else MuCAUSdB = '...'; MusCAUSgray = '...';
        end
        if isfield(ud.analyzed_muscles,'meanroi') && ~ isempty(ud.analyzed_muscles.meanroi)
            Mu = sprintf('Uncorr. echo int.: %3.2f [gr.lvl]',ud.analyzed_muscles.meanroi(p));
        else Mu = '...';
        end
        if isfield(ud.analyzed_muscles,'AvgFatThick') && ~ isempty(ud.analyzed_muscles.AvgFatThick);
            Fatl = sprintf('Fatl. thick: %3.2f [mm]',ud.analyzed_muscles.AvgFatThick(p)*10);
        else Fatl = '...';
        end
        if isfield(ud.analyzed_muscles,'SpLat') && ~ isempty(ud.analyzed_muscles.SpLat);
            SpLat = sprintf('Lat speckle: %2.2f [mm]',ud.analyzed_muscles.SpLat(p)*10);
        else SpLat = '...';
        end
        if isfield(ud.analyzed_muscles,'SpAx') && ~ isempty(ud.analyzed_muscles.SpAx);
            SpAx = sprintf('Ax speckle: %2.2f [mm]',ud.analyzed_muscles.SpAx(p)*10);
        else SpAx = '...';
        end
        
        if ~isnan(ud.analyzed_muscles.meanroi(p))
            if strcmp(PS.Project,'None')
                str = {Mu;Fatl};
                color = 'green';
            else
                str = {Mu;Fatl;MuCAUSdB;SpLat;SpAx};
                if sum(ud.analyzed_muscles.corrections(ud.autolines.currentfile,:))==5
                    color = 'green';
                else
                    color = 'red';
                end
            end
        else
            color = 'red';
            str = '';
        end
        
        pos = get(handles.figure1,'position');
        text(40,pos(4)-140,str,'Color',color,'Tag','Values')
    end
    
    [dummy,name,ext] = fileparts(ud.analyzed_muscles.dcmfiles{ud.autolines.currentfile});              % GW
    filename = fullfile(ud.path,[name,'.tif']);                             % GW filename without extension
    
    movegui(gcf)
    f=getframe; % 2013-07-24 GW: Doesn't work on second monitor...
    if ~isempty(ud.analyzed_muscles.rois{p})
        if ~isempty(f.colormap)
            imwrite(f.cdata,f.colormap,filename,'tiff','Compression','lzw');
        else
            imwrite(f.cdata,filename,'tiff','Compression','lzw');
        end
    end
    updatetitle(ud);
    %ud.reportimage{ud.autolines.currentfile} = filename;
    set(handles.figure1,'userdata',ud);
    
end

function updatetitle(ud)
if ud.analyzed_muscles.musclediam(ud.autolines.currentfile)==0
    if ~isempty(ud.analyzed_muscles.rois{ud.autolines.currentfile})
        tstr=sprintf('%s - %s',ud.analyzed_muscles.sides{ud.autolines.currentfile}, ud.analyzed_muscles.muscles{ud.autolines.currentfile});
        title(tstr,'color',[1 1 1]);
    else title('','color',[1 1 1]);
    end;
else
    tstr=sprintf('%s - %s, diam: %3.2f cm, subc: %3.2f cm',ud.analyzed_muscles.sides{ud.autolines.currentfile},...
        ud.analyzed_muscles.muscles{ud.autolines.currentfile},ud.analyzed_muscles.musclediam(ud.autolines.currentfile),ud.analyzed_muscles.fatlayer(ud.autolines.currentfile));
    title(tstr,'color',[1 1 1]);
end;

% --- Executes on button press in hist.
function hist_Callback(hObject, eventdata, handles)
% hObject    handle to hist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%warndlg('Not Implemented','Warning');
ud=get(handles.figure1,'userdata');
if ~isempty(ud.analyzed_muscles.rois{ud.autolines.currentfile})
    figure('Name',['Histogram: ' ud.current_muscle.muscle ' / image ' num2str(ud.autolines.currentfile)],'NumberTitle','off');
    hist(ud.Iroi,25);
    hold on
    m=mean(ud.Iroi);
    plot([m m],get(gca,'ylim'),'r','linewidth',2)
    xlabel('Echo intensity uncorrected [gr. lvl.]');
    ylabel('Number of pixels');
else
    errordlg('No ROI is drawn','Histogram error');
end;

% --- Executes on button press in saveresults.
function saveresults_Callback(hObject, eventdata, handles)
% hObject    handle to saveresults (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%%
save_results(handles.figure1,'end_result');


% --- Executes on button press in spierdikte.
function spierdikte_Callback(hObject, eventdata, handles)
% hObject    handle to spierdikte (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ud=get(handles.figure1,'userdata');

% check if current muscle diameter is already filled
for i=1:length(ud.analyzed_muscles.muscles)
    if i~=ud.autolines.currentfile
        if strcmp(ud.analyzed_muscles.muscles{i},ud.current_muscle.muscle) && strcmp(ud.analyzed_muscles.sides{i},ud.current_muscle.side )
            if (ud.analyzed_muscles.musclediam(i)~=0)
                errordlg(sprintf(['A diameter for this muscle (',char(ud.current_muscle.muscle),') is already given in image: %3d'],i),'Error','modal');
                return;
            end;
        end;
    end;
end;

prompt={'Muscle diameter: ','Fatlayer: '};
answer = {num2str(ud.analyzed_muscles.musclediam(ud.autolines.currentfile)) , num2str(ud.analyzed_muscles.fatlayer(ud.autolines.currentfile))};

for i=1:length(answer)
    if answer{i} == '0'
        answer{i}='';
    end
end

name='Muscle and fatlayer';
numlines=1;
answer=inputdlg(prompt,name,numlines,answer);
if isempty(answer)
    return;
end
err = chkinput(answer{1});
if ~isempty(answer) && ~isempty(answer{1}) && err == 0
    ud.analyzed_muscles.musclediam(ud.autolines.currentfile)=str2num(rmcomma(answer{1})); %#ok<*ST2NM>
end;

err = chkinput(answer{2});
if ~isempty(answer) && ~isempty(answer{2}) && err==0;
    ud.analyzed_muscles.fatlayer(ud.autolines.currentfile)=str2num(rmcomma(answer{2}));
end;
ud.analyzed_muscles.sides{ud.autolines.currentfile}=ud.current_muscle.side ;
ud.analyzed_muscles.muscles{ud.autolines.currentfile}=ud.current_muscle.muscle;
ud.analyzed_muscles.musclekeys{ud.autolines.currentfile}=ud.current_muscle.musclekey;
set(handles.figure1,'userdata',ud);
save_results(handles.figure1,'mid_result');
updatetitle(ud)

% --- Executes on button press in fasciculaties.
function fasciculaties_Callback(hObject, eventdata, handles)
% hObject    handle to fasciculaties (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ud=get(handles.figure1,'userdata');
if isfield(ud.analyzed_muscles,'fasc')
    if isfield(ud.analyzed_muscles.fasc,'key')
        fasc=fascic(ud.analyzed_muscles.fasc);
    else
        fasc=fascic();
    end;
else
    fasc=fascic();
end;
if ~isempty(fasc)
    ud.analyzed_muscles.fasc=fasc;
end;
set(handles.figure1,'userdata',ud);

% --- Executes on button press in patientdata.
function patientdata_Callback(hObject, eventdata, handles)
% hObject    handle to patientdata (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ud=get(handles.figure1,'userdata');
p.patient=ud.patient;
p.laborant=ud.laborant;
pat=patData(p,1);
%pat=patdata(ud.dcminfo);
if ~isempty(pat)
    ud.patient=pat.patient;
    ud.laborant=pat.laborant;
end;
set(handles.figure1,'userdata',ud);

%% save results
function [err] = save_results(figh,mode)

err = 0;
ud = get(figh,'userdata');
%try

s=0;
for i=1:length(ud.analyzed_muscles.muscles);
    s=s+~isempty(ud.analyzed_muscles.muscles{i});
end

if s~=0
    errmsg=infocomplete(ud);
    if ~isempty(errmsg);
        error(errmsg);
    end;
    
    %% results init GW
    % - Z-scores moeten nog opnieuw berekend worden aan de hand van
    % nieuwe normaalwaarden!
    
    zscores = 1;
    
    if (ud.musclestruct.EI_ref_check==1 || ud.musclestruct.thick_ref_check==1) && strcmp(mode,'end_result')
        
        r=getzscores(ud); %23-11-2014 EG: nieuwe versie
        
        if sum(r.number_zscores)>0
            zscores = 1;
        else
            %if strcmp(mode,'manual') % Do not display error in auto/recalc mode
            %    msgbox({'No Z-scores found for measured muscles.','However: all changes saved!'},'')
            zscores = 0;
            %end
        end
        
    else
        %msgbox('All changes saved','')
        zscores = 0;
    end
    
    if zscores
        
        % 2014-04-28 Backwards compatibility GW
        % muscleman function require muscle (.posFL) fields, who previously were stored in muscleman2.mat
        % To be integrated into Musclelist.txt!!!
        
        %load musclestruct2.mat % load muscle-struct with muscle positions for report images
        
        idx=1;
        
        if isfield(ud.analyzed_muscles,'fasc') && ~isempty(ud.analyzed_muscles.fasc);
            r.fasctotal = ['Total number of muscles with fasciculations: ',num2str(length(nonzeros(ud.analyzed_muscles.fasc.value)))];
            
            %createmuscleman(r.fasc, r.EI, ud.path);
            if  strcmp(mode,'end_result')
                createmuscleman(r,'zscore',ud.path,ud.musclestruct);           % changed ud.musclestruct towards muscle
                createmuscleman(r,'fasciculation',ud.path,ud.musclestruct);
                r.fasc_image =[ud.path '\' 'fasciculations','.jpg'];
                r.zscore_image =[ud.path '\' 'zscore','.jpg'];
            end
        else
            if  strcmp(mode,'end_result')
                createmuscleman(r,'zscore',ud.path,ud.musclestruct);
                r.zscore_image =[ud.path '\' 'zscore','.jpg'];
            end
        end;
        
        %         if isfield(ud,'reportimage');
        %             for i = 1 : length(ud.reportimage)
        %                 r.files(i+idx-1).file.name = 'reportimages';
        %                 r.files(i+idx-1).file.path = ud.reportimage(i);
        %             end
        %         end;
        
        r.conversion = 'QUMIA 3.0';
        r.machine=ud.machine;
        r.qumiaversion=ud.qumiaversion;
        
        %         %add nice muscle names
        %         for i = 1:length(r.metingen.muscle)
        %             %r.metingen.muscle{i}.name = convertname(r.metingen.muscle{i}.name,'magic2nice');
        %             r.metingen.muscle{i} = convertname(ud,r.metingen.muscle{i},'magic2nice');
        %         end
        
        % sort on musclekey
        %r.metingen.muscle = sortstruct(r.metingen.muscle);
        
        % store result structure in userdata, keep existing report info
        if isfield(ud,'resultstruct')
            if isfield(ud.resultstruct,'repinfo')
                r.repinfo=ud.resultstruct.repinfo;
            end;
        end;
        ud.resultstruct=r;
        
        % add date and time of analysis
        r.patient.uitwerkdatum = datestr(now,'YYYY-mm-dd HH:MM');
        
        % Create xml tree
        qumia_xml.accession_number = ud.dcminfo.AccessionNumber;
        qumia_xml.patient = r.patient;
        
        for m = 1:size(r.metingen.muscle,2)
            
            if isfield(r.metingen.muscle{m},'fasc')==0
                
                qumia_xml.muscle{m}.muscle_name = r.metingen.muscle{m}.name;
                qumia_xml.muscle{m}.side = r.metingen.muscle{m}.side;
                
                if isfield(r.metingen.muscle{m},'EI')
                    qumia_xml.muscle{m}.EI = r.metingen.muscle{m}.EI;
                    if ~isnan(r.metingen.muscle{m}.normal)
                        qumia_xml.muscle{m}.EI_normal = round(r.metingen.muscle{m}.normal);
                        qumia_xml.muscle{m}.EI_zscore = sprintf('%1.1f',r.metingen.muscle{m}.EIzscore);
                    else
                        qumia_xml.muscle{m}.EI_normal = '-';
                        qumia_xml.muscle{m}.EI_zscore = '-';
                    end
                else
                    qumia_xml.muscle{m}.EI = '-';
                    qumia_xml.muscle{m}.EI_normal = '-';
                    qumia_xml.muscle{m}.EI_zscore = '-';
                end
                
                if isfield(r.metingen.muscle{m},'diam')
                    qumia_xml.muscle{m}.thickness = sprintf('%1.2f',r.metingen.muscle{m}.diam);
                    if ~isnan(r.metingen.muscle{m}.diamnormal)
                        qumia_xml.muscle{m}.thickness_normal = sprintf('%1.2f',r.metingen.muscle{m}.diamnormal);
                        qumia_xml.muscle{m}.thickness_zscore = sprintf('%1.1f',r.metingen.muscle{m}.diamzscore);
                    else
                        qumia_xml.muscle{m}.thickness_normal = '-';
                        qumia_xml.muscle{m}.thickness_zscore = '-';
                    end
                else
                    qumia_xml.muscle{m}.thickness = '-';
                    qumia_xml.muscle{m}.thickness_normal = '-';
                    qumia_xml.muscle{m}.thickness_zscore = '-';
                end
            end
        end
        
        qumia_xml.laborant = r.laborant;
        qumia_xml.machine = r.machine;
        qumia_xml.qumiaversion = r.qumiaversion;
        
        if isfield(r,'zscore_image')
            
            %% replace drive letter with UNC path
            if strcmp(':',r.zscore_image(2))
                [status,cmdout] = dos(['net use ' r.zscore_image(1) ':']); cmdout = strsplit(cmdout);
                UNC = cmdout{find(strncmpi('\\',cmdout,2)==1)};
                r.zscore_image = strrep(r.zscore_image,r.zscore_image(1:2),[UNC]);
            end
            
            qumia_xml.zscore_image = strrep(r.zscore_image,'\','/');
        end
        if isfield(r,'fasc_image')
            
            %% replace drive letter with UNC path
            if strcmp(':',r.fasc_image(2))
                [status,cmdout] = dos(['net use ' r.fasc_image(1) ':']); cmdout = strsplit(cmdout);
                UNC = cmdout{find(strncmpi('\\',cmdout,2)==1)};
                r.fasc_image = strrep(r.fasc_image,r.fasc_image(1:2),[UNC]);
            end
            
            qumia_xml.fasc_image = strrep(r.fasc_image,'\','/');
        end
        
        ud.reportimage = {};
        imagelist = dir(fullfile(ud.path,'*.tif'));
        for i=1:size(imagelist,1)
            ud.reportimage{i} = fullfile(ud.path,imagelist(i).name);
        end
        
        if isfield(ud,'reportimage')
            a=1;
            if strcmp(':',ud.reportimage{i}(2))
                [status,cmdout] = dos(['net use ' ud.reportimage{i}(1) ':']); cmdout = strsplit(cmdout);
            end
            for i=1:size(ud.reportimage,2)
                if ~isempty(ud.reportimage{i})
                    
                    %% replace drive letter with UNC path
                    if strcmp(':',ud.reportimage{i}(2))
                        UNC = cmdout{find(strncmpi('\\',cmdout,2)==1)};
                        ud.reportimage{i} = strrep(ud.reportimage{i},ud.reportimage{i}(1:2),[UNC]);
                    end
                    
                    eval(['qumia_xml.image' num2str(a) ' = strrep(ud.reportimage{i},''\'',''/'');'])
                    
                    a=a+1;
                end
            end
        end
        
        t=struct2xml(qumia_xml);
        
        try
            if exist(fullfile(ud.path,'results.xml'),'file')==2
                delete(fullfile(ud.path,'results.xml'))
            end
            pause(1)
            save(t,fullfile(ud.path,'results.xml'));
        catch ME
            errormessage(['xml file save error. Error message' ME.message]);
            err = -1;
        end
        if  strcmp(mode,'end_result') % Show pop-up only at end
            showechoresultspopup(ud);
        end
    else
        if  strcmp(mode,'end_result') % Show pop-up only at end
            showechoresultspopup(ud);
        end
    end % estimate z-scores for reporting
    
    
else
    errordlg('Nothing to save');
    err = -1;
end

% save results as matlab data
if isfield(ud,'reportimage')
    reportimage=ud.reportimage;
else
    reportimage=[];
end
rois=ud.analyzed_muscles.rois;
meanroi=ud.analyzed_muscles.meanroi;
sides=ud.analyzed_muscles.sides;
muscles=ud.analyzed_muscles.muscles;
musclekeys=ud.analyzed_muscles.musclekeys;
normset=ud.analyzed_muscles.normset;
fatlayer=ud.analyzed_muscles.fatlayer;
musclediam=ud.analyzed_muscles.musclediam;
patient=ud.patient;
laborant=ud.laborant;
fasc=[];
dcmfiles=ud.analyzed_muscles.dcmfiles;
if isfield(ud.analyzed_muscles,'fasc')
    fasc=ud.analyzed_muscles.fasc;
end;
%    conversion=r.conversion;
machine=ud.machine;
qumiaversion=ud.qumiaversion;
calip=ud.autolines.calip;
at=ud.autolines.at;
%     musclestruct = ud.musclestruct;

% NEW variables added: 203-07-24, by GW: MUSIC
corrections = ud.analyzed_muscles.corrections;
meanroi_rel_dB = ud.analyzed_muscles.meanroi_rel_dB;
Project=ud.analyzed_muscles.Project;
SpAx=ud.analyzed_muscles.SpAx;
SpLat=ud.analyzed_muscles.SpLat;
SpMethod=ud.analyzed_muscles.SpMethod;
fatcontour=ud.analyzed_muscles.fatcontour;
AvgFatThick=ud.analyzed_muscles.AvgFatThick;

save(fullfile(ud.path,'roi','anal.mat'),'Project','rois','meanroi','meanroi_rel_dB','sides','muscles',...
    'musclediam','fatlayer','patient','laborant','fasc','qumiaversion',...
    'machine','dcmfiles','calip','at','musclekeys','normset',...
    'AvgFatThick','fatcontour','SpAx','SpLat','SpMethod','corrections','reportimage'); % 203-07-24 GW, MUSIC
set(figh,'userdata',ud);

%catch ME
%    errormessage(['Error saving data. Error message: ' ME.message]) ;
%end

% --------------------------------------------------------------------
function Echo_ContextMenu_RemoveRoi_Callback(hObject, eventdata, handles)
% hObject    handle to Echo_ContextMenu_RemoveRoi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ud = get(handles.figure1,'userdata');

% clear roi data and remove mat file
if ~isempty(ud.analyzed_muscles.roihndl)
    delete(ud.analyzed_muscles.roihndl);
    ud.analyzed_muscles.roihndl=[];
end;

% ud.analyzed_muscles.rois{ud.autolines.currentfile}=[]; %HST
ud.analyzed_muscles.rois{ud.autolines.currentfile}=[];
ud.analyzed_muscles.meanroi(ud.autolines.currentfile)=0;
%ud.reportimage(ud.autolines.currentfile)=[];

if exist([ud.storepath '\' ud.analyzed_muscles.dcmfiles{ud.autolines.currentfile} '.mat'],'file')
    delete([ud.storepath '\' ud.analyzed_muscles.dcmfiles{ud.autolines.currentfile} '.mat']);
    delete([ud.path '\' ud.analyzed_muscles.dcmfiles{ud.autolines.currentfile}(1:end-4) '.tif']);
end

ud=displayimage(ud,handles);
set(handles.figure1,'userdata',ud);

%----------------------------------------------------------------------
function varargout = chkinput(varargin)
% Usage:
%   chkinput(inputstring, hObject)
%   chkinput(inputstring)

if (~isempty(varargin{1}) && isnan(str2double(varargin{1})))
    if nargin ==2
        uicontrol(varargin{2});
    end
    errordlg({'Error in entered number'},'Wrong input');
    if nargout ==1
        varargout{1} = 1;
    end
else
    if nargout ==1
        varargout{1} = 0;
    end
end

% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
%set(handles.filenr,'string',[num2str(ud.autolines.currentfile),' - ',num2str(length(ud.analyzed_muscles.dcmfiles))]);

try
    ud = get(handles.figure1,'userdata');
    v=round(get(hObject,'value'));
    set(hObject,'value',v);
    if length(ud.analyzed_muscles.dcmfiles)-v <ud.autolines.currentfile
        ud.autolines.currentfile=length(ud.analyzed_muscles.dcmfiles)-v+2;
        [ud,err]=previousfile(ud,handles);
        if err==-1 return; end;
    else
        ud.autolines.currentfile=length(ud.analyzed_muscles.dcmfiles)-v;
        [ud, err]=nextfile(ud,handles);
        if err==-1 return; end;
    end;
    set(handles.figure1,'userdata',ud);
catch ME
    errormessage(['Unable to display next image. Error message' ME.message]);
end

% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.

% function [tmpstruct] = sortstruct(musclestruct)
% % sorts the measurments results according to the musclekeys
% %
% for i = 1:length(musclestruct)
%     sortarray(i) = musclestruct{i}.musclekey;
% end
% [sortded, orgidx] = sort(sortarray);
%
% tmpstruct=musclestruct;
% for i = 1:length(musclestruct)
%     tmpstruct{i} = musclestruct{orgidx(i)};
% end

% --- Executes on button press in zoomin.
function zoom_Callback(hObject, eventdata, handles)
% hObject    handle to zoomin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of zoomin
zoom

function errormessage(message)
err = [];

response = questdlg({message, '','Would you like to e-mail the error report?',''},...
    'QUMIA error','Yes','No','Yes');
%uiwait(errordlg({message, '' , err.message},'Qumia error','modal'));
if strcmp(response,'Yes')
    ud = get(gcf,'userData');
    mail = 'qumiamail@gmail.com'; % qumia GMail email address
    password = 'mailqumia'; % GMail password
    
    % Then this code will set up the preferences properly:
    setpref('Internet','E_mail',mail);
    setpref('Internet','SMTP_Server','smtp.gmail.com');
    setpref('Internet','SMTP_Username',mail);
    setpref('Internet','SMTP_Password',password);
    props = java.lang.System.getProperties;
    props.setProperty('mail.smtp.auth','true');
    props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');
    props.setProperty('mail.smtp.socketFactory.port','465');
    
    mailmsg=sprintf('%s %s\nUser:%s\nMachine:%s\n',message,err.message,getenv('USERNAME'),getenv('COMPUTERNAME'));
    if ~isempty(ud)
        % make data anonymous
        ud.current_muscle.muscle_image=[];
        ud.Iconv=[];
        ud.Iroi=[];
        ud.patient.patientid=[];
        save([ud.path '\err.mat_'],'ud','err');
        sendmail('qumiamail@gmail.com','QUMIA error message',mailmsg,[ud.path '\err.mat_']);
    else
        sendmail('qumiamail@gmail.com','QUMIA error message',mailmsg);
    end;
end;

% --------------------------------------------------------------------
function manual_Callback(hObject, eventdata, handles)
% hObject    handle to manual (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
open('Quick manual qumia.pdf');
% --------------------------------------------------------------------
function about_Callback(hObject, eventdata, handles)
% hObject    handle to about (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ud = get(handles.figure1, 'UserData');
msgbox({'QUMIA';'(c) Copyright Radboud university medical center';...
    'Please refer to the manual for contact information.';ud.qumiaversion});


% set the right muscle selection in the user interface
function ud=setmuscleselection (ud, handles)

% cont = get(handles.muscle,'String');
% i = strcmp(cont,ud.analyzed_muscles.muscles{ud.autolines.currentfile});          % Zoek gelijken in korte lijst

% Check if muscle is previously selected
prev_muscle = ud.analyzed_muscles.muscles{ud.autolines.currentfile};
prev_key    = ud.analyzed_muscles.musclekeys{ud.autolines.currentfile};
musclelist  = get(handles.MuscleList,'String');         % All muscles names

index = 0;
for n=1:length(musclelist)
    if strcmp(musclelist{n},prev_muscle)
        index = n;
        break
    end
end

if index
    muscle_name = musclelist{index};
    set(handles.MuscleList,'value',index)               % select previous musclename
    
    % Do nothing
    %     cur = get(handles.MuscleList,'Value');              % current selected
    %     cur_musclename = musclelist(cur);
    %     prev_key = ud.analyzed_muscles.musclekeys{ud.autolines.currentfile};
    %     keyboard
end

if strcmp(ud.analyzed_muscles.sides{ud.autolines.currentfile},'L')
    set(handles.links,'Value',1);
    set(handles.rechts,'value',0);
    ud.current_muscle.side ='L';
else
    set(handles.links,'Value',0);
    set(handles.rechts,'value',1);
    ud.current_muscle.side ='R';
end;

ud.current_muscle.muscle=ud.analyzed_muscles.muscles{ud.autolines.currentfile};
ud.current_muscle.musclekey=ud.analyzed_muscles.musclekeys{ud.autolines.currentfile};

% --- Executes on button press in caliper.
function caliper_Callback(hObject, eventdata, handles)
% hObject    handle to caliper (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

addcaliper(handles);

function addcaliper(handles)

figh=handles.figure1;
ud=get(figh,'userdata');

% change mousecursor
set(figh,'pointer','cross');
if length(ud.autolines.calip.cnt)>=ud.autolines.currentfile
    if ud.autolines.calip.cnt(ud.autolines.currentfile)<12 %HVD CALIP
        ud.autolines.calip.cnt(ud.autolines.currentfile)=ud.autolines.calip.cnt(ud.autolines.currentfile)+1;
    else
        errordlg('Maximum number of calipers reached','Error');
        set(figh,'pointer','arrow');
        return;
    end;
else
    ud.autolines.calip.cnt(ud.autolines.currentfile)=1;
end;

% on mouseclick save position and put a marker on that position
key=waitforbuttonpress;
while key~=0
    key=waitforbuttonpress; % wait for mouse button
end;

ccnt=ud.autolines.calip.cnt(ud.autolines.currentfile); % current counter

pt = get(gca,'CurrentPoint');
h=plot(pt(1,1),pt(1,2),'y','marker',ud.autolines.calip.markers(ccnt),'markersize',8);
set(h,'tag',['1',num2str(ccnt)]);
ud.autolines.calip.handle(ccnt,1)=h;
drawnow;

% on next mouseclick  position and put second marker on that position
key=waitforbuttonpress;
while key~=0
    key=waitforbuttonpress; % wait for mouse button
end;
pt2 = get(gca, 'CurrentPoint');
h=plot(pt2(1,1),pt2(1,2),'y','marker',ud.autolines.calip.markers(ccnt),'markersize',8);
set(h,'tag',['2',num2str(ccnt)]);
ud.autolines.calip.handle(ccnt,2)=h;

% store positions and calculate distance and return
ud.autolines.calip.pts{ud.autolines.currentfile}.x(ccnt,:)=[pt(1,1) pt2(1,1)];
ud.autolines.calip.pts{ud.autolines.currentfile}.y(ccnt,:)=[pt(1,2) pt2(1,2)];
ud.autolines.calip.xres(ud.autolines.currentfile)=ud.dcminfo.SequenceOfUltrasoundRegions.Item_1.PhysicalDeltaX;
ud.autolines.calip.yres(ud.autolines.currentfile)=ud.dcminfo.SequenceOfUltrasoundRegions.Item_1.PhysicalDeltaY;

set(figh,'userdata',ud);
[ud.autolines.calip]=caliperdistance(ud.autolines.calip,ud.autolines.currentfile);
% put distance text on the screen
ud.autolines.calip=puttext(ud.autolines.calip,ud.autolines.currentfile);

set(ud.autolines.calip.handle(ccnt,1),'buttondownfcn','qumia(''edit_caliper'',gcbo,[],guidata(gcbo))');
set(ud.autolines.calip.handle(ccnt,2),'buttondownfcn','qumia(''edit_caliper'',gcbo,[],guidata(gcbo))');
set(figh,'pointer','arrow');
set(figh,'userdata',ud);

function edit_caliper(hObject, eventdata, handles)
if strcmp(get(handles.figure1,'selectionType'),'normal')
    set(handles.figure1,'windowbuttonmotionfcn','qumia(''move_caliper'',gcbo,[],guidata(gcbo))');
    set(handles.figure1,'windowbuttonupfcn','qumia(''endedit_caliper'',gcbo,[],guidata(gcbo))');
else
    displaycontextmenu(hObject,handles);
end;

function move_caliper(hObject, eventdata, handles)

% move caliper with mouse cursor
ud=get(handles.figure1,'userdata');
pt = get(gca, 'CurrentPoint');
set(gco,'Xdata',pt(1,1));
set(gco,'Ydata',pt(1,2));

function endedit_caliper(hObject, eventdata, handles)

% store current position in userdata struct
set(handles.figure1,'WindowButtonMotionFcn',[]);
set(handles.figure1,'WindowButtonUpFcn',[]);
ud=get(handles.figure1,'userdata');
ptx=get(gco,'Xdata');
pty=get(gco,'Ydata');
ctag=get(gco,'tag');
ctag=str2num(ctag);
if ctag<20 || (ctag>100&&ctag<200)
    if ctag>100
        caliper=ctag-100;
    else
        caliper=ctag-10;
    end;
    ctag=1;
else
    if ctag>200
        caliper=ctag-200;
    else
        caliper=ctag-20;
    end;
    ctag=2;
end;
ud.autolines.calip.pts{ud.autolines.currentfile}.x(caliper,ctag)=ptx;
ud.autolines.calip.pts{ud.autolines.currentfile}.y(caliper,ctag)=pty;
set(handles.figure1,'userdata',ud);

[ud.autolines.calip]=caliperdistance(ud.autolines.calip,ud.autolines.currentfile);
% put distance text on the screen
ud.autolines.calip=puttext(ud.autolines.calip,ud.autolines.currentfile);
set(handles.figure1,'userData',ud);

function [calip]=caliperdistance(calip,currentfile)

xres=calip.xres(currentfile);
yres=calip.yres(currentfile);
for mcnt=1:calip.cnt(currentfile)
    x=calip.pts{currentfile}.x(mcnt,:);
    y=calip.pts{currentfile}.y(mcnt,:);
    dx=diff(x).*xres;
    dy=diff(y).*yres;
    d=sqrt(dx^2+dy^2);
    calip.distance{currentfile}(mcnt)=d;
end;

function calip=puttext(calip,currentfile)

if isfield(calip,'text')
    delete(calip.text.th);
    delete(calip.text.ph);
    drawnow;
end;

for mcnt=1:calip.cnt(currentfile)
    str=sprintf('%.3f cm',calip.distance{currentfile}(mcnt));
    position=[130 200+(mcnt-1)*30];
    calip.text.th(mcnt)=text(position(1),position(2),str,'color','y');
    calip.text.ph(mcnt)=plot(100,position(2),calip.markers(mcnt),'color','y');
end;

function ud=plotcalipers(ud)

ud.autolines.calip.handle=[];
if isfield(ud.autolines.calip,'text')
    ud.autolines.calip=rmfield(ud.autolines.calip,'text');
end;
if length(ud.autolines.calip.cnt)<ud.autolines.currentfile
    return;
end;
for ccnt=1:ud.autolines.calip.cnt(ud.autolines.currentfile)
    ptx=ud.autolines.calip.pts{ud.autolines.currentfile}.x(ccnt,1);
    pty=ud.autolines.calip.pts{ud.autolines.currentfile}.y(ccnt,1);
    h=plot(ptx,pty,'y','marker',ud.autolines.calip.markers(ccnt),'markersize',8);
    set(h,'tag',['1',num2str(ccnt)]);
    ud.autolines.calip.handle(ccnt,1)=h;
    
    ptx=ud.autolines.calip.pts{ud.autolines.currentfile}.x(ccnt,2);
    pty=ud.autolines.calip.pts{ud.autolines.currentfile}.y(ccnt,2);
    h=plot(ptx,pty,'y','marker',ud.autolines.calip.markers(ccnt),'markersize',8);
    set(h,'tag',['2',num2str(ccnt)]);
    ud.autolines.calip.handle(ccnt,2)=h;
    
    set(ud.autolines.calip.handle(ccnt,1),'buttondownfcn','qumia(''edit_caliper'',gcbo,[],guidata(gcbo))');
    set(ud.autolines.calip.handle(ccnt,2),'buttondownfcn','qumia(''edit_caliper'',gcbo,[],guidata(gcbo))');
end;

[ud.autolines.calip]=caliperdistance(ud.autolines.calip,ud.autolines.currentfile);
% put distance text on the screen
ud.autolines.calip=puttext(ud.autolines.calip,ud.autolines.currentfile);
showcalipers(ud,ud.autolines.calip.visible)

function DeleteCaliper_Callback(hObject, eventdata, handles)

ud=get(handles.figure1,'userdata');
ctag=get(gco,'tag');
ctag=str2num(ctag);
if ctag<20 || (ctag>100&&ctag<200)
    caliper=ctag-10;
    ctag=1;
else
    caliper=ctag-20;
    ctag=2;
end;
delete(ud.autolines.calip.handle);
ud.autolines.calip.cnt(ud.autolines.currentfile)=ud.autolines.calip.cnt(ud.autolines.currentfile)-1;
ud.autolines.calip.pts{ud.autolines.currentfile}.x(caliper,:)=[];
ud.autolines.calip.pts{ud.autolines.currentfile}.y(caliper,:)=[];
delete(ud.autolines.calip.text.th);
delete(ud.autolines.calip.text.ph);
ud=plotcalipers(ud);
set(handles.figure1,'userdata',ud);

function displaycontextmenu(hObject,handles)
hcm=uicontextmenu;
uimenu(hcm,'label','Delete caliper','callback','qumia(''DeleteCaliper_Callback'',gcbo,[],guidata(gcbo))');
set(hObject,'uicontextmenu',hcm);

% --------------------------------------------------------------------
function DeleteCalipers_Callback(hObject, eventdata, handles)
% hObject    handle to DeleteCalipers (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ud=get(handles.figure1,'userdata');
if length(ud.autolines.calip.cnt)<ud.autolines.currentfile return; end;
if ud.autolines.calip.cnt(ud.autolines.currentfile)<=0 return; end;
delete(ud.autolines.calip.handle);
delete(ud.autolines.calip.text.th);
delete(ud.autolines.calip.text.ph);
ud.autolines.calip=rmfield(ud.autolines.calip,'text');
ud.autolines.calip.cnt(ud.autolines.currentfile)=0;
ud.autolines.calip.pts{ud.autolines.currentfile}.x(:,:)=[];
ud.autolines.calip.pts{ud.autolines.currentfile}.y(:,:)=[];
ud.autolines.calip.handle=[];
ud.autolines.calip.distance=[];
set(handles.figure1,'userdata',ud);

function showcalipers(ud,visible)
if ishandle(ud.autolines.calip.handle)
    set(ud.autolines.calip.handle,'visible',visible);
    set(ud.autolines.calip.text.th,'visible',visible);
    set(ud.autolines.calip.text.ph,'visible',visible);
end;

% --------------------------------------------------------------------
function DeleteAnnotations_Callback(hObject, eventdata, handles)
% hObject    handle to delete_annotation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ud=get(handles.figure1,'userdata');
checked=get(hObject,'checked');
if strcmp(checked,'on')
    set(handles.caliper,'enable','on')
    set(hObject,'checked','off');
    ud.autolines.calip.visible='on';
else    set(handles.caliper,'enable','off')
    set(hObject,'checked','on');
    ud.autolines.calip.visible='off';
end;
showcalipers(ud,ud.autolines.calip.visible)
set(handles.figure1,'userdata',ud);

% --------------------------------------------------------------------
function saveresults_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to saveresults (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

save_results(handles.figure1,'end_result');

% --------------------------------------------------------------------
function open_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to open (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

open_dir(handles);

% --------------------------------------------------------------------
function manual_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to manual (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

open('Quick manual qumia.pdf');

% --------------------------------------------------------------------
function zoomin_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to zoomin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%zoomin;


function errmsg=infocomplete(ud)

errmsg=[];
if ~isfield(ud.patient,'leeftijd')
    errmsg='The age of the subject is unknown.';
    return;
end;
if ~isfield(ud.patient,'geslacht')
    errmsg='The sex of the subject is unknown.';
    return;
end;
if ~isfield(ud.patient,'gewicht')
    errmsg='The weight of the subject is unknown.';
    return;
end;
% check if all patient info is there
if isempty(ud.patient.leeftijd) || isnan(ud.patient.leeftijd)
    errmsg='The age of the subject is unknown.';
    return;
end;
if isempty(ud.patient.geslacht) || isnan(ud.patient.geslacht)
    errmsg='The sex of the subject is unknown.';
    return;
end;
if isempty(ud.patient.gewicht) || isnan(ud.patient.gewicht)
    errmsg='The weight of the subject is unknown.';
    return;
end;

% --------------------------------------------------------------------
function area_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to area (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ud=get(gcf,'userdata');
h = imellipse(gca);
fcn = makeConstrainToRectFcn('imellipse',get(gca,'XLim'),get(gca,'YLim'));
setPositionConstraintFcn(h,fcn);
p=wait(h);
msk=h.createMask;
dx=ud.dcminfo.SequenceOfUltrasoundRegions.Item_1.PhysicalDeltaX;
text=sprintf('Area = %4.3f cm^2',dx*dx*length(nonzeros(msk)));
Msgbox(text)
delete(h)
%keyboard;


% --- Executes on button press in genreport.
function genreport_Callback(hObject, eventdata, handles)
% hObject    handle to genreport (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%try
save_results(handles.figure1,'end_result');
ud=get(handles.figure1,'userdata');

% copy data to output folder

% fileparts = strsplit(ud.path,filesep);
% if exist([ud.output_path filesep fileparts{end}],'dir')==0
%     mkdir([ud.output_path filesep fileparts{end}])
% end

copyfile([ud.path filesep 'results.xml'],ud.output_path);
% if exist([ud.path filesep 'fasciculations.jpg'])
%     copyfile([ud.path filesep 'fasciculations.jpg'],[ud.output_path filesep fileparts{end}]);
% end
% if exist([ud.path filesep 'zscore.jpg'])
%     copyfile([ud.path filesep 'zscore.jpg'],[ud.output_path filesep fileparts{end}]);
% end
% if isfield(ud,'reportimage')
%     for i=1:size(ud.reportimage,2)
%         if ~isempty(ud.reportimage{i})
%             copyfile(ud.reportimage{i},[ud.output_path filesep fileparts{end}]);
%         end
%     end
% end

choice = questdlg('Report succesfully send to Epic. Close results?','','Yes','No','Yes');
switch choice
    case 'Yes'
        close('Echo results')
        try
            close('Fasciculations patient')
        catch
        end
        try
            close('Z-scores patient')
        catch
        end
end

set(handles.figure1,'userData',ud);
% catch ME
%     errormessage(['Error generating report. Error message: ', ME.message]);
% end;


% --------------------------------------------------------------------
function genreport_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to genreport (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

genreport_Callback(hObject, eventdata, handles);


% --- Executes on scroll wheel click while the figure is in focus.
function ScrollCallback(hObject, eventdata)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	VerticalScrollCount: signed integer indicating direction and number of clicks
%	VerticalScrollAmount: number of lines scrolled for each click
% handles    structure with handles and user data (see GUIDATA)

handles=guihandles;
ud=get(handles.figure1,'userdata');
if eventdata.VerticalScrollCount > 0
    ud=nextfile(ud,handles);
else
    ud=previousfile(ud,handles);
end;

function imagebuttondown(hObject,eventdata,handles)
if strcmp(get(handles.figure1,'selectionType'),'normal')
    % call roi callback
    %ROI_Callback(hObject, 1, handles)
end;

% --------------------------------------------------------------------
function annotation_toolbar_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to annotation_toolbar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ud=get(handles.figure1,'userdata');
try
    at=inputdlg('Enter annotation: ','',1);
    if ~isempty(at)
        h=gtext(at);
        set(h,'color','y');
        pos=get(h,'position');
        if ~isempty(ud.autolines.at) && ud.autolines.currentfile<=length(ud.autolines.at)
            if exist(ud.autolines.at{ud.autolines.currentfile},'text')
                l=length(ud.autolines.at{ud.autolines.currentfile}.text);
            else
                l=0;
            end
        else
            l=0;
        end;
        ud.autolines.at{ud.autolines.currentfile}.text{l+1}=at;
        ud.autolines.at{ud.autolines.currentfile}.pos{l+1}=pos;
    end
catch ME
end

set(handles.figure1,'userdata',ud);

function filelist=getdicomfiles(folder)

h=waitbar(0,'Please wait while loading dicom files...');
try
    filelist=[];
    cnt=1;
    d=dir(fullfile(folder,'*.*'));
    for i=1:length(d)
        if d(i).isdir==0
            if isdicom(fullfile(folder,d(i).name))
                filelist(cnt).name = d(i).name;
                filelist(cnt).date = d(i).date;
                filelist(cnt).bytes = d(i).bytes;
                filelist(cnt).datenum = d(i).datenum;
                filelist(cnt).isdir = d(i).isdir;
                dcmi=dicominfo(fullfile(folder,d(i).name));
                filelist(cnt).filenr=dcmi.InstanceNumber;
                cnt=cnt+1;
            end;
        end;
        waitbar(i/length(d));
    end;
    close(h);
catch ME
    close(h)
    error(ME.message)
end;


function plotruler(xres,yres)

cb=get(gcf,'WindowScrollWheelFcn');
p=ginput(2);
set(gcf,'WindowScrollWheelFcn',cb);
h=line(p(:,1),[p(1,2) p(1,2)],'color','w');
set(h,'ButtonDownFcn','qumia(''move_ruler'',gcbo,[],guidata(gcbo))')
stepsize=0.25/xres;
nsteps=diff(p(:,1))/stepsize+1;
for cnt=1:nsteps
    x=p(1,1)+(cnt-1)*stepsize;
    y=p(1,2);
    hstep(cnt)=line([x x],[y+5 y-5],'color','w');
end;
set(h,'userdata',hstep);

function move_ruler(hObject, eventdata, handles)
if strcmp(get(handles.figure1,'selectionType'),'normal')
    set(handles.figure1,'windowbuttonmotionfcn','qumia(''move_ruler_now'',gcbo,[],guidata(gcbo))');
    set(handles.figure1,'windowbuttonupfcn','qumia(''endmove_ruler'',gcbo,[],guidata(gcbo))');
end;

function move_ruler_now(hObject, eventdata, handles)

pt = get(gca, 'CurrentPoint');
hstep=get(gco,'userdata');
xdata=get(gco,'xdata');
ydata=get(gco,'ydata');
diffx=pt(1,1)-xdata(1);
diffy=pt(1,2)-ydata(1);
set(gco,'xdata',xdata+diffx);
set(gco,'ydata',ydata+diffy);
for cnt=1:length(hstep)
    xdata=get(hstep(cnt),'xdata');
    ydata=get(hstep(cnt),'ydata');
    set(hstep(cnt),'xdata',xdata+diffx);
    set(hstep(cnt),'ydata',ydata+diffy);
end;

function endmove_ruler(hObject, eventdata, handles)
set(handles.figure1,'WindowButtonMotionFcn',[]);
set(handles.figure1,'WindowButtonUpFcn',[]);

% --------------------------------------------------------------------
function ruler_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to ruler (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ud=get(handles.figure1,'userdata');
plotruler(ud.dcminfo.SequenceOfUltrasoundRegions.Item_1.PhysicalDeltaX,ud.dcminfo.SequenceOfUltrasoundRegions.Item_1.PhysicalDeltaY);


% --- Executes on scroll wheel click while the figure is in focus.
function figure1_WindowScrollWheelFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	VerticalScrollCount: signed integer indicating direction and number of clicks
%	VerticalScrollAmount: number of lines scrolled for each click
% handles    structure with handles and user data (see GUIDATA)

handles=guihandles;
ud=get(handles.figure1,'userdata');
if eventdata.VerticalScrollCount > 0
    ud=nextfile(ud,handles);
else
    ud=previousfile(ud,handles);
end;


% --------------------------------------------------------------------
function delete_musclesize_Callback(hObject, eventdata, handles)
% hObject    handle to delete_musclesize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ud=get(handles.figure1,'userdata');
ud.analyzed_muscles.musclediam(ud.autolines.currentfile)=0;
ud.analyzed_muscles.fatlayer(ud.autolines.currentfile)=0;
set(handles.figure1,'userdata',ud);
updatetitle(ud)


function retval=diameter_alreadyset(ud)
if (ud.analyzed_muscles.musclediam(ud.autolines.currentfile)~=0)
    % check if current muscle diameter is already filled
    for i=1:length(ud.analyzed_muscles.muscles)
        if i~=ud.autolines.currentfile
            if strcmp(ud.analyzed_muscles.muscles{i},ud.current_muscle.muscle) && strcmp(ud.analyzed_muscles.sides{i},ud.current_muscle.side )
                if (ud.analyzed_muscles.musclediam(i)~=0)
                    errordlg('A diameter for this muscle is already given, remove a diameter first','Error','modal');
                    retval=1;
                    return;
                end;
            end;
        end;
    end;
end;
retval=0;

function [roi dcm_roi roi_red]= ROIdetect(I,c,SupportLine)

roi = [];
dcm_roi = [];
roi_red = [];

delete(findobj('Tag','sector'))

[h,w]=size(I);

%% Detect Sector position
% c = ud.cal;
if ~isempty(c)
    if isfield(c,'RegionLocationMinY0')
        xmin = c.RegionLocationMinX0;
        xmax = c.RegionLocationMaxX1;
        ymin = c.RegionLocationMinY0;
        ymax = c.RegionLocationMaxY1;
        dcm_roi(1,:) = [xmin xmax xmax xmin xmin];
        dcm_roi(2,:) = [ymin ymin ymax ymax ymin];
        if SupportLine
            plot(dcm_roi(1,:),dcm_roi(2,:),':y','tag','sector')
        end
        
        %% Find Top-y (first value > 100)
        topy = [];
        for n=ymin:ymax/2 % search top (y=0) until half depth
            mu = round(mean(I(n,(w/4:w-w/4))));
            if mu > 1, topy = n; break; end
        end
        if isempty(topy), topy = ymin; end
        
        % find left roi x
        hr = ymax-ymin;
        mul = round(max(I(round(ymin+(hr/4)):round(ymax-hr/4),xmin:round(round((xmax+xmin)/2))))); % avg values of half height column until half width of ROI
        %         mul = round(mean(I(round(h/4):round(h-h/4),xmin:round(round((xmax+xmin)/2))),1)); % avg values of half height column until half width of ROI
        xil = find(mul>20,1,'first');
        if isempty(xil)
            xl = xmin; % start total left
        else xl = xmin+xil;
        end
        
        % find right roi x
        mur = round(max(I(round(ymin+(hr/4)):round(ymax-hr/4),round((xmax+xmin)/2):xmax))); % avg values of half height column until half width of ROI
        %         mur = round(mean(I(round(h/4):round(h-h/4),round((xmax+xmin)/2):xmax),1)); % avg values of half height column until half width of ROI
        xir = find(mur<20,1,'first');
        if isempty(xir)
            xr = xmax; % start total right
        else xr = round((xmax+xmin)/2)+xir;
        end
        
        roix = [xl xr xr xl xl];
        roiy = [topy topy ymax ymax topy];
        if SupportLine
            plot(roix,roiy,':r','tag','sector');
        end
        roi = [roix; roiy]; % Exact data ROI
        
        %% +/- 15% Reduced ROI-data (save region)
        p15 = (xr-xl)*0.15;
        roix = [xl+p15 xr-p15 xr-p15 xl+p15 xl+p15];
        roiy = [topy topy ymax ymax topy];
        if SupportLine
            plot(roix,roiy,':g','tag','sector');
        end
        roi_red = [roix; roiy]; % Reduced ROI
        
    end
else
    disp('Calibration error...')
end

% --- Executes on button press in Fatlayer.
function Fatlayer_Callback(hObject, eventdata, handles)
% hObject    handle to Fatlayer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ud = get(handles.figure1,'userdata');
p = ud.autolines.currentfile;

% Show original Image data first
cla; imagesc(ud.current_muscle.muscle_image); colormap(gray)
set(gca,'CLim',[0 max(ud.current_muscle.muscle_image(:))])
axis off; axis tight; zoom off;
set(gca,'dataaspectratio',[1 1 1]);

if ~isempty(ud.analyzed_muscles.rois{p});
    plot(ud.analyzed_muscles.rois{p}(1,:),ud.analyzed_muscles.rois{p}(2,:),'-.g','LineWidth',2)
end

% GW Not needed???
% ud.current_muscle.cal = GetDcmCalInfo(ud.dcminfo);                     % Get calibration from dcm file
% ud.current_muscle.roi = ROIdetect(ud.current_muscle.muscle_image,ud.current_muscle.cal,ud.autolines.SupportFig);                                 % Auto detect real ROI data

[x,y] = getline(gcf);                                       % selected xy values
if length(x)<2 % not enough points
    ud.analyzed_muscles.fatcontour{ud.autolines.currentfile} = [];                     % (erase current border)
    set(handles.ROI,'ForeGroundColor',[0.08, 0.17, 0.5])
else
    ud.analyzed_muscles.fatcontour{ud.autolines.currentfile} = [x,y];
    set(handles.ROI,'ForeGroundColor',[0, 0, 0])
end
set(handles.figure1,'userdata',ud);

% CORRECT FATLAYER ATTENUATION and SHOW CORRECTED IMAGE
ud = displayimage(ud,handles);                          % Update after manual fatlayer determination
set(handles.figure1,'userdata',ud)                      % Set back data struct

% function ShowFatcontour(ud)
% xwrd = 1:size(ud.current_muscle.muscle_image,2);                                                      % Border X-value
% fatborder = ud.analyzed_muscles.fatcontour{ud.autolines.currentfile};
% x = fatborder(:,1);
% y = fatborder(:,2);
% if isfield(ud,'roi') && ~isempty(ud.current_muscle.roi)
%     xwrd = double([ud.current_muscle.roi(1,1):ud.current_muscle.roi(1,2)]);                               % x wrd for real ROI-data width
% end
% contour = interp1(x, y, xwrd, 'spline', 'extrap');                          % Border Y-values
% plot(xwrd,contour,':c','LineWidth',2,'tag','fatcontour')                    % Plot total contour


% --- Executes on button press in SupportFig.
function SupportFig_Callback(hObject, eventdata, handles)
ud = get(handles.figure1,'userdata');
ud.autolines.SupportFig = get(gcbo,'value');
if ~get(gcbo,'value')
    delete(findobj('Tag','speckle'))    % Deletes active specklesize figure
end
set(handles.figure1,'userdata',ud);
if ~isempty(ud.autolines.currentfile) && ~(ud.autolines.currentfile == 0)
    ud = displayimage(ud,handles);          % Display Speckle-Size figure
end

% --------------------------------------------------------------------
function config_Callback(hObject, eventdata, handles)

ProjectSettings(get(handles.figure1,'userdata'));

% --- Executes on button press in btn_SupportLines.
function btn_SupportLines_Callback(hObject, eventdata, handles)
ud = get(handles.figure1,'userdata');
ud.autolines.SupportLine = get(gcbo,'value');
if ~get(gcbo,'value')
    delete(findobj('Tag','sector'))                                 % Deletes sector and ROI rectangles lines
    delete(findobj('Tag','Values'))                                 % Deletes currect ROI & FatlThick values
    delete(findobj('Tag','LUT'));                                   % Deletes LUT position
end
set(handles.figure1,'userdata',ud);
if ~isempty(ud.autolines.currentfile) && ~(ud.autolines.currentfile == 0)
    ud = displayimage(ud,handles);                                      % Display corrected Image and supportlines
end

% --- Executes on selection change in ProjectSelect.
function ProjectSelect_Callback(hObject, eventdata, handles)
ud = get(handles.figure1,'userdata');                               % Load analysis struct
Settings = LoadProjectSettings(ud.projectsfile,ud.qumia_path);          % load all up to date settings
selected = get(gcbo,'value');                                               % id of current selected
ud.ProjectSettings = Settings;                                              % all project settings
ud.curProject = GetCurrentProjectSettings(Settings,selected);               % Get current settings struct
ud.curProject.id = selected;
ud.analyzed_muscles.Project{ud.autolines.currentfile} = ud.curProject.Project;                         % Change the global variable

if strcmp(ud.analyzed_muscles.Project(ud.autolines.currentfile),'None')
    set(handles.SupportFig,'Enable','Off','Visible','Off')
else
    set(handles.SupportFig,'Enable','On','Visible','On')
end

%set(handles.txt_Projects,'ForeGroundColor',[0, 0, 0])
%set(handles.ProjectSelect,'ForeGroundColor',[0, 0, 0])

% apply and show corrections based on adjusted projectsettings
if ~isempty(ud.autolines.currentfile) && ~(ud.autolines.currentfile == 0)
    ud = displayimage(ud,handles);                                      % Display corrected Image and supportlines
end
set(handles.figure1,'userdata',ud)                                  % Set back adjusted projectsettings

function cur = GetCurrentProjectSettings(PS,id)
cur.Project = PS.Project{id};
cur.Background = PS.Background(id);
cur.gamma = PS.gamma(id);
cur.Fc = PS.Fc(id);
cur.Att = PS.Att(id);
cur.DepthProfileFLoc = PS.DepthProfileFLoc{id};
cur.LUTposFLoc = PS.LUTposFLoc{id};

function roi = ReduceROI(roi,roi_red)
x = roi(1,:);                           % interactive roi x points
x(x<roi_red(1,1))=roi_red(1,1);         % limit roi width to sector width
x(x>roi_red(1,2))=roi_red(1,2);         % limit roi width to sector width
y = roi(2,:);                           % interactive roi y points
y(y<roi_red(2,2))=roi_red(2,2);         % limit roi heigth to sector height
y(y>roi_red(2,3))=roi_red(2,3);         % limit roi heigth to sector height
roi = [x; y];                           % limit roi

% --- Executes on selection change in MuscleList.
function MuscleList_Callback(hObject, eventdata, handles)
changemuscle(handles);

function changemuscle(handles)

ud = get(handles.figure1,'userdata');
if ~(ud.autolines.currentfile == 0)
    list = get(handles.MuscleList,'String');
    value = get(handles.MuscleList,'value');
    ud.current_muscle.muscle = list{value};
    
    % find corresponding muscle key
    found = 0;
    for n=1:length(ud.musclestruct.name)
        if strcmp(ud.musclestruct.name{n},ud.current_muscle.muscle)
            found = 1;
            break
        end
    end
    if found
        ud.current_muscle.musclekey = ud.musclestruct.key(n);
        ud.analyzed_muscles.muscles{ud.autolines.currentfile}=ud.current_muscle.muscle;
        ud.analyzed_muscles.musclekeys{ud.autolines.currentfile}=ud.current_muscle.musclekey;
        set(handles.figure1,'userdata',ud);
        %set(handles.txt_musclelist,'ForeGroundColor',[0, 0, 0])
        set(handles.MuscleList,'ForeGroundColor',[0, 0, 0])
        updatetitle(ud)
    end
else
    uiwait(msgbox({'Please select a patient first!'}))
    return
end


function show_musclelist(ud)
%[ud.sorted_list] = sort_muscle_list(ud.muscle_names,ud.muscle_states);
for n=1:length(ud.sorted_list)
    if strcmp(ud.sorted_list{n},ud.current_muscle.muscle)
        set(findobj('Tag','MuscleList'),'String',ud.sorted_list,'Value',n)
        updatetitle(ud)
        break
    end
end


function [names_sort]=sort_muscle_list(names,state)

% find muscle category/state indici
i1 = find(state==1);     % Top of list
i0 = find(state==0);     % rest of list
i2 = find(state==2);     % do not show this muscles (deleted)

% sort by musclename

names_sort = sort(names(i1));
if ~isempty(i1)
    L = length(names_sort);
    names_sort{L+1,1} = '-------------------------';
end
l = length(i0);
L = length(names_sort);
names_sort(L+1:L+l) = sort(names(i0));

function MuscleList_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function ProjectSelect_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --------------------------------------------------------------------
function mnu_recalc_Callback(hObject, eventdata, handles)
% hObject    handle to mnu_recalc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ud=get(handles.figure1,'userdata');
pdir = uigetdir(ud.defaultpath);
if ~isempty(pdir) || pdir==0
    patients = dir(pdir);
    
    M = find([patients.isdir]==1,1,'first')+1;
    S = M+1;
    L = length(patients);
    h_bar = waitbar(0,'saving and recalculating results.....');
    p = 1; %pointer for totalresults structure
    for n=S:L
        
        if patients(n).isdir
            patdir = [pdir,'\',patients(n).name]
            roifile = fullfile(pdir,patients(n).name,'roi','anal.mat');
            
            %% delete possible previously loaded variables
            if exist('muscles','var'), clear('muscles'); end
            if exist('dcmfiles','var'), clear('dcmfiles'); end
            if exist('Project','var'), clear('Project'); end
            if exist('rois','var'), clear('rois'); end
            if exist('sides','var'), clear('sides'); end
            %if exist('results','var'), clear('results'); end
            
            %% Load previously analyzed data
            if exist(roifile,'file') % Previous analysis available
                roi_info = dir(roifile);
                load(roifile)
                change = 0;
                if exist('muscles','var') && exist('dcmfiles','var') && exist('Project','var') && exist('rois','var') && exist('sides','var')
                    
                    %% Load DICOM data
                    for i=1:length(dcmfiles)
                        
                        
                        %% Check if all required vales are pressent
                        if ~isempty(muscles{i}) && ~isempty(Project{i}) && ~isempty(rois{i}) && ~isempty(sides{i}) || (fatlayer(i)~=0 || musclediam(i)~=0)
                            
                            change = 1;
                            
                            muscle=muscles{i}; prj=Project{i}; roi=rois{i}; side=sides{i};
                            dcmfile = fullfile(patdir,dcmfiles{i});
                            info = dicominfo(dcmfile);
                            I = dicomread(info);
                            % GW: Take a weighted combination of all colors (ROI data is unaffected since gr.lvl are same over alle RGB layers!!!
                            if ndims(I)==3
                                I = double(.2989*I(:,:,1)+.5870*I(:,:,2)+.1140*I(:,:,3));
                            end
                            
                            name = dcmfiles{i}; disp_name = '';
                            if length(name)>20, l2 = length(name); disp_name = ['...',name(l2-20:end)];
                            else disp_name = name;
                            end
                            
                            
                            %% Save changed/recalculated results to  total results struct.
                            % patient info
                            results(p).patientid = patient.patientid;
                            results(p).patienname = patient.name;
                            results(p).gebdat = patient.geboortedatum;
                            results(p).lengte = patient.lengte;
                            results(p).gewicht = patient.gewicht;
                            results(p).geslacht = patient.geslacht;
                            results(p).leeftijd = patient.leeftijd;
                            results(p).meetdatum = patient.meetdatum;
                            results(p).kant = patient.kant;
                            results(p).laborant = laborant.naam;
                            
                            % file info
                            results(p).roi_date = roi_info.date;        % Date of last roi-save
                            results(p).path = pdir;
                            results(p).fullfile = dcmfile;
                            results(p).muscle = muscles{i};
                            results(p).side = sides{i};
                            
                            %% Recalc CAUS results or take diameters & fatlayerthickness
                            if fatlayer(i)~=0
                                results(p).fatlayer = fatlayer(i);
                                results(p).musclediam = musclediam(i);
                            end
                            if ~isempty(roi)
                                %% Recalc result from current patient/image
                                res = [];
                                res = recal_results(ud,I,info,muscle,prj,roi,side);     % Recalc results (CAUS core: auto fatlayer)
                                if ~isempty(res) % Overwrite previous results
                                    
                                    
                                    
                                    AvgFatThick(i) = res.AvgFatThick;
                                    meanroi(i) = res.meanroi;
                                    meanroi_rel_dB(i) = res.meanroi_rel_dB;
                                    SpAx(i) = res.SpAx;
                                    SpLat(i) = res.SpLat;
                                    SpMethod{i} = res.SpMethod;
                                    
                                    % calculated results
                                    results(p).fat = res.AvgFatThick*10;        % cm>mm
                                    results(p).mu_uncorr = res.meanroi;         % absolute gr.lvl
                                    results(p).mu_sd = res.sdroi;
                                    results(p).mu_rel_dB = res.meanroi_rel_dB;  % relative dB level to phantom
                                    results(p).mu_rel_gray = res.meanroi_rel_dB * res.Project.gamma + res.Project.Background; % Relative gray level to phantom
                                    results(p).ax = res.SpAx;                % mm
                                    results(p).lat = res.SpLat;              % mm
                                    results(p).sp_method = res.SpMethod;
                                    
                                    % calculated results UTC
                                    results(p).mu_rel_dB_UTC = res.UTC_MU.mu;
                                    results(p).mu_RAC_UTC = res.UTC_MU.RAC;
                                    results(p).SD_mu_UTC = res.UTC_SD.mu;
                                    results(p).SNR_mu_UTC = res.UTC_SNR.mu;
                                    
                                    % Project Settings
                                    results(p).project = res.Project.Project;
                                    results(p).Background = res.Project.Background;
                                    results(p).gamma = res.Project.gamma;
                                    results(p).Fc = res.Project.Fc;
                                    results(p).Att = res.Project.Att;
                                    results(p).DepthProfileFLoc = res.Project.DepthProfileFLoc;
                                    results(p).LUTposFLoc = res.Project.DepthProfileFLoc;
                                end
                            end
                            p = p + 1;
                        end % do something with results
                    end % for loop dicomfiles
                    
                    %% SAVE RECALCULATED/CHANGED RESULTS PER PATIENT
                    if change % Results were recalculated
                        
                        %% recalc zscores
                        res.analyzed_muscles.muscles = muscles;           % gekozen namen
                        res.analyzed_muscles.meanroi = meanroi;           % berekende uncorrected EI
                        res.analyzed_muscles.musclediam = musclediam;      % dikte
                        res.analyzed_muscles.sides = sides;
                        res.analyzed_muscles.fatlayer = fatlayer;  % gekozen kant
                        res.analyzed_muscles.fasc = fasc;
                        res.patient = patient;
                        res.laborant = laborant;
                        res.musclestruct.name = ud.musclestruct.name;
                        res.musclestruct.key = ud.musclestruct.key;
                        %res.musclestruct.form.thickness = ud.musclestruct.form.thickness; %z_score dikte
                        %res.musclestruct.form.EI=ud.musclestruct.form.EI; %z_score Ei
                        res.musclestruct.model=ud.musclestruct.model; %z_score Ei
                        res.qumia_path = ud.qumia_path;
                        
                        new_zscores{n-S+1}=getzscores(res);
                        
                        save(roifile,'Project','rois','meanroi','meanroi_rel_dB','sides','muscles',...
                            'musclediam','fatlayer','patient','laborant','fasc','qumiaversion',...
                            'machine','dcmfiles','calip','musclekeys','normset',...
                            'AvgFatThick','fatcontour','SpAx','SpLat','SpMethod','corrections'); % 2013-07-24 GW, MUSIC
                    end
                end % end if
            end
        end
        waitbar((n-M)/(L-S+1),h_bar)
    end%for patient
    close(h_bar)
    
    %% Save total results to file
    if exist('results','var')
        if ~isempty(results)
            Save_QUMIA_Results(ud,pdir,results,new_zscores)
        end
    end
end

function Save_QUMIA_Results(ud,map,r,z_scores)

%% GENERATE ALL RESULTS (.XLSX) FILE

d = round(datevec(datestr(clock)));
date = sprintf('%02d_%02d_%02d_%02d_%02d_%02d',d);
File = [map,'\!',date,'_All_Results.csv'];

%output_module 1
fields{1} = {'patientid','patienname','gebdat','lengte','gewicht','geslacht',...
    'leeftijd','kant','meetdatum','roi_date','laborant','path','muscle','side'};
tags{1} = {'ID','Name','Birthdate','Lenght','Weight','Sex',...
    'Age','Dominance','Measurement date','Analysis date','Technician','File path','Muscle','Side'};

%output_module 2
fields{2} = {'fatlayer','musclediam','mu_uncorr','mu_sd'};
tags{2} = {'Fat_layer','Thickness','Absolute gray level','SD absolute gray level'};

%output_module 3
fields{3} = {'mu_rel_dB','mu_rel_gray','ax','lat','sp_method','mu_rel_dB_UTC','mu_RAC_UTC','SD_mu_UTC','SNR_mu_UTC'};
tags{3} = {'Relative dB level','Relative gray level','Axial speckle size','Lateral speckle size','Speckle method','UTC_MU_mu','UTC_MU_RAC','UTC_SD_mu','UTC_SNR_mu'};

%output_module 4
fields{4} = {'project','Background','gamma','Fc','Att','DepthProfileFLoc','LUTposFLoc'};
tags{4} = {'Phantom','Background','Gamma','Fc','Att','Depth correction','LUT correction'};

modules= [1 2];
if sum(strcmp({r.project},'None')+cellfun('isempty', {r.project})) < length(r)
    modules=[modules 3 4];
end

selected_fields=[]; selected_tags=[];
for i=modules
    selected_fields = [selected_fields fields{i}];
    selected_tags = [selected_tags tags{i}];
end

for p=1:length(r)
    for n=1:length(selected_fields)
        eval(['charornot=ischar(r(',num2str(p),').',selected_fields{n},');'])
        eval(['value=r(',num2str(p),').',selected_fields{n},';'])
        
        resstr{p,n} = value;
    end
end

xlswrite(File,[selected_tags;resstr]);

% [nrows,ncols] = size(resstr);formatHeader=[]; formatData=[];
% for col=1:ncols
%     formatHeader = [formatHeader ';%s'];
%
%     if ischar(resstr{1,col})
%         formatData = [formatData ';%s'];
%     else
%         formatData = [formatData ';%3.2f'];
%     end
% end
%
% fileID = fopen(File,'w');
%
% fprintf(fileID,[formatHeader(2:end) '\r\n'],selected_tags{1,:});
% for row = 1:nrows
%     fprintf(fileID,[formatData(2:end) '\r\n'],resstr{row,:});
% end
%
% fclose(fileID);


%% GENERATE AVERAGE RESULTS (.XLSX) FILE

AvgFile = [map,'\!',date,'_Averaged_Results.xlsx'];
qumia_avg_results(r,AvgFile,z_scores,ud.musclestruct)

uiwait(msgbox('Stored recalculated results.'))

function res = recal_results(ud,I,info,muscle,prj,roi,side)

res = [];
Settings = ud.ProjectSettings;
Project = []; % init project name
for n=1:length(Settings.Project)
    if strcmp(Settings.Project{n},prj)
        Project = GetCurrentProjectSettings(Settings,n);               % Get current settings struct
        break
    end
end

Project.id=n;

if ~isempty(Project)
    cal = info.SequenceOfUltrasoundRegions.Item_1;
    [roidata roidcm roired] = ROIdetect(I,cal,0);
    
    [Iconv,Iroi,Icorr,res,fatcontour] = convertimage_caus(ud.qumia_path,ud.ProjectSettings,Project,I,roi,roidata,roired,roidcm,cal,0);
    res.Project = Project;
end


% --------------------------------------------------------------------
function project_settings_Callback(hObject, eventdata, handles)
% hObject    handle to project_settings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ProjectSettings(get(handles.figure1,'userdata'));


% --------------------------------------------------------------------
function delete_annotation_Callback(hObject, eventdata, handles)
% hObject    handle to delete_annotation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ud=get(handles.figure1,'userdata');

% plot annotations if included
if ~isempty(ud.autolines.at)
    if ud.autolines.currentfile<=length(ud.autolines.at)
        if isfield(ud.autolines.at{ud.autolines.currentfile},'text')
            for i=1:length(ud.autolines.at{ud.autolines.currentfile}.text);
                ud.autolines.at{ud.autolines.currentfile} = [];
                ud=displayimage(ud,handles);
            end
        end
    end
end

set(handles.figure1,'userdata',ud);


% --------------------------------------------------------------------
function Echo_ContextMenu_Callback(hObject, eventdata, handles)
% hObject    handle to Echo_ContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function ImportROIs_Callback(hObject, eventdata, handles)
% hObject    handle to ImportROIs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ud = get(handles.figure1, 'UserData');

hw=waitbar(0,'One moment please ...','name','Import ROIs');
l=length(ud.analyzed_muscles.dcmfiles);

for i=1:length(ud.analyzed_muscles.dcmfiles)
    try
        roimat=load(fullfile(ud.storepath,[ud.analyzed_muscles.dcmfiles{i},'.mat']));
        ud.analyzed_muscles.rois{i} = roimat.roi;
        ud.analyzed_muscles.sides{i} = roimat.side;
        ud.analyzed_muscles.muscles{i} = roimat.muscle;
        if isfield(roimat,'musclekey')
            ud.analyzed_muscles.musclekeys{i}=roimat.musclekey;
        end;
    catch ME
        ud.rois{i} = [];
        %         errormessage(['No ROIs available' ME.message]);
    end
    waitbar(i/l,hw);
end
close(hw);

set(handles.figure1,'UserData',ud);


% --------------------------------------------------------------------
function config_folder_Callback(hObject, eventdata, handles)
% hObject    handle to config_folder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ud.qumia_path = uigetdir(cd,'Select folder with qumia configuration');
fid_new = fopen(fullfile(cd,'qumia_config_path.ini'),'wt');
fprintf(fid_new,'%s\n','[PATH]');
fprintf(fid_new,'%s','qumia_config_path=');
fprintf(fid_new,'%s',ud.qumia_path);
fclose(fid_new);

msgbox('Restart qumia to load new settings','')

