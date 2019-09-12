function varargout = ProjectSettings(varargin)
% PROJECTSETTINGS MATLAB code for ProjectSettings.fig
%      PROJECTSETTINGS, by itself, creates a new PROJECTSETTINGS or raises the existing
%      singleton*.
%
%      H = PROJECTSETTINGS returns the handle to a new PROJECTSETTINGS or the handle to
%      the existing singleton*.
%
%      PROJECTSETTINGS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PROJECTSETTINGS.M with the given input arguments.
%
%      PROJECTSETTINGS('Property','Value',...) creates a new PROJECTSETTINGS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ProjectSettings_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ProjectSettings_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ProjectSettings

% Last Modified by GUIDE v2.5 17-Jun-2016 15:27:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ProjectSettings_OpeningFcn, ...
                   'gui_OutputFcn',  @ProjectSettings_OutputFcn, ...
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


% --- Executes just before ProjectSettings is made visible.
function ProjectSettings_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ProjectSettings (see VARARGIN)

% Choose default command line output for ProjectSettings
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ProjectSettings wait for user response (see UIRESUME)
% uiwait(handles.ProjectSettings);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Place input into handles sturcture

ud = get(findobj('tag','figure1'),'UserData');
if isfield(ud,'projectsfile') && exist(ud.projectsfile,'file')
    
    if isfield(ud,'curProject') && ~isempty(ud.curProject)
        if isfield(ud.curProject,'id') && ~ isempty(ud.curProject.id)
            curID = ud.curProject.id;
        else
            curID = 1;
        end
    else
        curID = 1;
    end 
    Defaults = GetCurSetting(handles);
    if isfield(ud,'ProjectSettings') && ~isempty(ud.ProjectSettings)
         Settings = ud.ProjectSettings;
%     else Settings = LoadProjectSettings(ud.projectsfile); % To be deleted...
    end
    Settings.Defaults = Defaults;                       % backup defaults (in case of new project config)
    
    Settings.file = ud.projectsfile;
    
    % Check if project is previously selected
    if isfield(ud,'curProject')
        if isfield(ud.curProject,'id') && ~isempty(ud.curProject.id)
            Settings.currentproject = ud.curProject.id;
        else
            Settings.currentproject = 1;                % default (select first project)
        end
    else
        Settings.currentproject = 1;                    % default (select first project)
    end
    set(handles.ProjectSettings,'UserData',Settings)
    
    DisplaySettings(handles,Settings);
else
    disp('no good')
end

function SaveSettings(Settings)
 	eol = Settings.eol;
    sep = Settings.sep; 
    
    fid = fopen(Settings.file,'w');  
    
    % Save header to file
    hdr = '';
    for n=1:length(Settings.header), hdr = [hdr Settings.header{n} sep]; end
    hdr = [hdr(1:end-1) eol];
    fprintf(fid,hdr);
    
    % Save (changed) data to file
    L = length(Settings.Project);
    for n=1:L
        str = '';
        for m=1:length(Settings.header)
            field = Settings.header{m};
            type = Settings.types(m*2);
            if strcmp(type,'s')
                eval(['value = Settings.',field,'{',num2str(n),'};'])
                value = strrep(value,'\','/');
                str = [str value sep];
            else
                eval(['value = Settings.',field,'(',num2str(n),');'])
                str = [str sprintf('%4.2f',value) sep];
            end
        end
        str = [str(1:end-1) eol]; % Remove last sep symbol
        fprintf(fid,str);
    end

function DisplaySettings(handles,Settings)
    p = Settings.currentproject;
    set(handles.edit_projectname,'String',Settings.Project(p))
    set(handles.projects,'String',Settings.Project,'Value',p)
    set(handles.edit_Atten,'string',Settings.Att(p))
    set(handles.edit_gamma,'string',Settings.gamma(p))
    set(handles.edit_background,'string',Settings.Background(p))
    set(handles.edit_Fc,'string',Settings.Fc(p))
    set(handles.edit_depthprofile,'string',Settings.DepthProfileFLoc(p))
    set(handles.edit_LUTposFile,'string',Settings.LUTposFLoc(p))

function Settings = GetSettings(handles,Settings)
    p = Settings.currentproject;
    Settings.Project(p) = get(handles.edit_projectname,'String');
    Settings.Att(p) = str2double(get(handles.edit_Atten,'string'));
    Settings.gamma(p) = str2double(get(handles.edit_gamma,'string'));
    Settings.Background(p) = str2double(get(handles.edit_background,'string'));
    Settings.Fc(p) = str2double(get(handles.edit_Fc,'string'));
    Settings.DepthProfileFLoc(p) = get(handles.edit_depthprofile,'string');
    Settings.LUTposFLoc(p) = get(handles.edit_LUTposFile,'string');
    
    set(handles.ProjectSettings,'UserData',Settings) % Save possible changes
    
function Setting = GetCurSetting(handles)
    Setting.Project = char(get(handles.edit_projectname,'String'));
    Setting.Att = str2double(get(handles.edit_Atten,'string'));
    Setting.gamma = str2double(get(handles.edit_gamma,'string'));
    Setting.Background = str2double(get(handles.edit_background,'string'));
    Setting.Fc = str2double(get(handles.edit_Fc,'string'));
    Setting.DepthProfileFLoc = char(get(handles.edit_depthprofile,'string'));
    Setting.LUTposFLoc = char(get(handles.edit_LUTposFile,'string'));
    
% --- Outputs from this function are returned to the command line.
function varargout = ProjectSettings_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function btn_new_Callback(hObject, eventdata, handles)

% Set Default values to new entry
Settings = get(handles.ProjectSettings,'UserData');
p = length(Settings.Project)+1; % New project pointer
Defaults = Settings.Defaults;
fields = fieldnames(Defaults);
for n=1:length(fields)
    field = fields{n};
    type = Settings.types(n*2);
    if strcmp(type,'s')
        eval(['Settings.',field,'{',num2str(p),'}=Defaults.',field,';'])
    else
        eval(['Settings.',field,'(',num2str(p),')=Defaults.',field,';'])
    end
end
Settings.currentproject = p;
set(handles.ProjectSettings,'UserData',Settings);   % remember settings
DisplaySettings(handles,Settings)                   % Show new created projectsettings

function projects_Callback(hObject, eventdata, handles)
Settings = get(handles.ProjectSettings,'UserData');
Settings.currentproject = get(gcbo,'value');
set(handles.ProjectSettings,'UserData',Settings);
DisplaySettings(handles,Settings)

function btn_saveuse_Callback(hObject, eventdata, handles)

ud = get(findobj('tag','figure1'),'UserData'); 
Settings = get(handles.ProjectSettings,'UserData');
Settings = GetSettings(handles,Settings);

SaveSettings(Settings)                                  % Save possible changed settings

ud.curProject = GetCurSetting(handles);                       % Current Setting structure
ud.curProject.id = get(findobj('tag','projects'),'value');    % Current selected item (project)

ud.ProjectSettings = Settings;                          % All/edited projects

if isfield(ud,'Project') && ~isempty(ud.Project)
    ud.Project{ud.currentfile} = ud.curProject.Project;     % change selected selected project look-up
end

ID = get(findobj('Tag','projects'),'value');
Projects = Settings.Project;
set(findobj('Tag','ProjectSelect'),'String',Projects,'value',ID);
set(findobj('tag','figure1'),'UserData',ud);
close(findobj('tag','ProjectSettings'))
uiwait(msgbox('Current Image will not be updated untill this Image is selected again!'))

function btn_del_Callback(hObject, eventdata, handles)
Settings = get(handles.ProjectSettings,'UserData');
curID = get(findobj('tag','projects'),'value');

curProject = Settings.Project{curID};
answer = questdlg(['Sure to delete: ',curProject,'?'],'Sure to delete?','Yes','No','No');
switch answer
    case 'Yes'
        ind = 1:length(Settings.Project);   % all indici
        ind(curID) = [];                    % Valid indici (all but removed)
        
        hdr = Settings.header;
        for n=1:length(hdr)
            field = hdr{n};
            eval(['Settings.',field,'=Settings.',field,'([',num2str(ind),']);'])
        end
        SaveSettings(Settings)        
        Settings.currentproject = 1;        % Reset pointer to first item
        DisplaySettings(handles,Settings)
        set(handles.ProjectSettings,'UserData',Settings)
        
        btn_saveuse_Callback([],[],handles)
        
    case 'No'
        return
end

function btn_beamprofile_Callback(hObject, eventdata, handles)
ud = get(findobj('tag','figure1'),'UserData');
PS = get(handles.ProjectSettings,'UserData');
curPS = GetCurSetting(handles);
if isfield(curPS,'DepthProfileFLoc') 
    if ~isempty(char(curPS.DepthProfileFLoc))
        [path,n,e] = fileparts(char(curPS.DepthProfileFLoc));
        path = uigetdir(path,'Select folder in which (homogeneous) phantom images for beamprofile estimation are located');
        files = dir(path);
    else
        path = uigetdir('d:\','Select folder in which (homogeneous) phantom images for beamprofile estimation are located');
        files = dir(path);
    end
end
[avg, info]= AverageFiles(path,files);

if isfield(ud.current_muscle,'roi') && ~ isempty(ud.current_muscle.roi)
    roi = ud.current_muscle.roi;
else roi = [];
end

if isfield(ud.current_muscle,'cal') && ~ isempty(ud.current_muscle.cal)
    cal = ud.current_muscle.cal;
else cal = [];
end

if isempty(roi) || isempty(cal)
    disp('Load QUMIA image first')
    return
else
    
    xr = (roi(1,2)-roi(1,1))*0.20; % pixels to reduce roi (29% left and right)
    beamprofile = mean(avg(roi(2,1):roi(2,3),roi(1,1)+xr:roi(1,2)-xr),2);
    depth = length(beamprofile)*cal.PhysicalDeltaY;
    
    figure('tag','beamprofile')
    set(gca,'fontweight','bold')
    title(['depth: ',num2str(depth),' [cm]']), hold on
    plot(beamprofile,'b','LineWidth',2)
    uiwait(msgbox({'Select start and end point of beamprofile','Neglect peaks at start and end of curve for optimal curve-fit results!'}))
    [x,dummy]=getpts();
    x = round(x);
    ylim = get(gca,'YLim');
    
    fit_order = 11;
    xfull = [1:length(beamprofile)]';
    xfit = [x(1):x(2)]';
    yfit = beamprofile(x(1):x(2));
    Fit = polyfit(xfit,yfit,fit_order);
    PVAL = polyval(Fit,xfit);
       
    Start = ones(x(1),1)*PVAL(1)-1;                     % First part (before first click) with first value of FIT
    End = ones((length(xfull)-x(2)-1),1)*PVAL(end);     % Last part (after last click) with last value of FIT
    BeamProfileFit = [Start; PVAL; End];                % Combine to total curve
    plot(xfull,BeamProfileFit,'r','LineWidth',2)
    plot([x(1) x(1)],ylim,':r')
    plot([x(2) x(2)],ylim,':r')
    hl = legend('BeamProfile','PolyFit (11th order)','Selected fit range');
    set(hl,'Location','best')
    xlabel('depth [px]')
    ylabel('echlevel [gr.lvl]')
    
    file = char(curPS.DepthProfileFLoc);
    [path,name,ext] = fileparts(file);
    file = [path,'/',name,'.mat'];  % Must be .mat file!!!
    if exist(file,'file')
        answer = questdlg('Sure to overwrite previous beamprofile?', ...
            'Overwrite previous analysis?','Yes','No','Yes');
        switch answer
            case 'No'
                name = inputdlg('Give new filename:','new filename',1,{name});
                file = [path,'\',char(name),'.mat'];
        end
    else
        path = uigetdir(path,'Select folder for saving LUT position');
        file = [path,'\',char(curPS.Project),'_beamprofile.mat'];
    end
    [p,n,dummy] = fileparts(file);
    figfile = [p,'\',n,'.png'];
    print(gcf,'-dpng','-r100',figfile)
    save(strrep(file,'/','\'),'info','avg','beamprofile','BeamProfileFit','cal','roi','depth','Fit','fit_order')
    set(handles.edit_depthprofile,'String',{[name,'.mat']})
    
end

function [avg,info] = AverageFiles(path,files)

t = 1;
for n=3:length(files)
    if ~isdir([path,'\',files(n).name])
        [dummy,name,ext]=fileparts(files(n).name);
        if strcmp(ext,'.dcm') || isempty(ext)
            info = dicominfo([path,'\',files(n).name]);
            I = dicomread(info);
            if length(size(I))>2
                I = double(.2989*I(:,:,1)+.5870*I(:,:,2)+.1140*I(:,:,3));
            end
            avg(:,:,t) = I;
            t = t + 1;
        end
    end
end
avg = mean(avg,3);

function btn_LUTposMAT_Callback(hObject, eventdata, handles)

Setting = GetCurSetting(handles);

ud = get(findobj('tag','figure1'),'UserData');
if ~isfield(ud.current_muscle,'muscle_image') || isempty(ud.current_muscle.muscle_image)
    uiwait(msgbox('Please open image first before changing project settings'))
    return
end
lut = 0;
if isfield(Setting,'LUTposFLoc') && ~isempty(Setting.LUTposFLoc)
    LUTfile = char(Setting.LUTposFLoc);
    figure(findobj('tag','figure1'))
    if exist(LUTfile,'file')
        % Ask overwrite!
%         lut = 1;
    else
        lut = 0;
    end
end

if ~lut
    uiwait(msgbox({'Select LUT (gray wedge) coursly from Image!','Avoid text and other information!',' - Thus: Only LUT and black pixels!'}))

    figure(findobj('tag','figure1'))
    r = round(getrect(gcf));

     % Find new max (top y)
    tmplut = ud.current_muscle.muscle_image(r(2):r(2)+r(4),r(1):r(1)+r(3));
    tmp = mean(tmplut,2);
    [maxv,maxi] = max(tmp);     % y start is max lut value
    r(2) = r(2)+maxi-1;         % edit topy
    r(4) = r(4)-maxi-1;         % reduce height with found max index

    % Find end point of lut (min y)
    tmplut = ud.current_muscle.muscle_image(r(2):r(2)+r(4),r(1):r(1)+r(3));
    tmp = mean(tmplut,2);
    [minv,mini] = min(tmp);     % y end point is lowest amplitude pixel 
    r(4) = mini;                % reduce height to lowest value

    % Find left and right sides
    tmplut = ud.current_muscle.muscle_image(r(2):r(2)+r(4),r(1):r(1)+r(3));
    tmp = round(mean(tmplut,1)); % average and remove noise by round
    i1 = find(tmp>0,1,'first');
    i2 = find(tmp>0,1,'last');
    r(1) = r(1)+i1-1;           % start index of 
    r(3) = i2-i1;               % width of valid part
    
    x = [r(1) r(1)+r(3) r(1)+r(3) r(1) r(1)];
    y = [r(2) r(2) r(2)+r(4) r(2)+r(4) r(2)];
    plot(x,y,'y')

    file = char(Setting.LUTposFLoc);
    [p,n,e] = fileparts(file);
    file = [p,'/',n,'.mat'];  % Must be .mat file!!!
    if exist(file,'file')
        answer = questdlg('Sure to overwrite previous lut position?', ...
            'Overwrite previous LUT postition?','Yes','No','Rename','Rename');
        switch answer
            case 'Rename'
                name = inputdlg('Give new filename:','new filename',1,{n});
                file = [p,'\',char(n),'.mat'];
            case 'No'
                return
        end
    else
        path = uigetdir(ud.path,'Select folder for saving LUT position');
        file = [path,'\',char(Setting.Project),'_lutpos.mat'];
    end
    
%     path = uigetdir('d:\','Select folder for saving LUT position');
%     LUTposFILE = [path,'\',char(Setting.Project),'_lutpos.mat'];
    save(file,'r','x','y')
    set(handles.edit_LUTposFile,'String',{[n,'.mat']})

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% UNUSED AUTOGENERTED CODE:

function projects_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_Atten_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_LUTposFile_Callback(hObject, eventdata, handles)
function edit_background_Callback(hObject, eventdata, handles)
function edit_Atten_Callback(hObject, eventdata, handles)
function edit_depthprofile_Callback(hObject, eventdata, handles)
function edit_projectname_Callback(hObject, eventdata, handles)
function edit_projectname_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_depthprofile_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_background_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_gamma_Callback(hObject, eventdata, handles)
function edit_gamma_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_Fc_Callback(hObject, eventdata, handles)
function edit_Fc_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_LUTposFile_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



