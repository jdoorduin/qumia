function varargout = showechoresultspopup(varargin)
% SHOWECHORESULTSPOPUP M-file for showechoresultspopup.fig
%      SHOWECHORESULTSPOPUP, by itself, creates a new SHOWECHORESULTSPOPUP or raises the existing
%      singleton*.
%
%      H = SHOWECHORESULTSPOPUP returns the handle to a new SHOWECHORESULTSPOPUP or the handle to
%      the existing singleton*.
%
%      SHOWECHORESULTSPOPUP('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SHOWECHORESULTSPOPUP.M with the given input arguments.
%
%      SHOWECHORESULTSPOPUP('Property','Value',...) creates a new SHOWECHORESULTSPOPUP or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before showechoresultspopup_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to showechoresultspopup_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help showechoresultspopup

% Last Modified by GUIDE v2.5 27-Nov-2009 13:35:18

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @showechoresultspopup_OpeningFcn, ...
                   'gui_OutputFcn',  @showechoresultspopup_OutputFcn, ...
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


% --- Executes just before showechoresultspopup is made visible.
function showechoresultspopup_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to showechoresultspopup (see VARARGIN)

% Choose default command line output for showechoresultspopup
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
if size(varargin,2)==1
    results = varargin{1};
%     musclecnt = size(results(1).diam.muscle,2)
%     resstring{1} = ' Diameter:';
%     for idx = 1:musclecnt;
%         resstring{idx+1} = sprintf('  %-14s %-7s %s',results.diam.muscle{idx}.name, results.diam.muscle{idx}.side,  num2str(results.diam.muscle{idx}.value,3));
%     end
%     resstring{idx+3} = ' Echo:';
%     lastidx = idx+3;
%     musclecnt = size(results.EI.muscle,2)
%     for idx = 1:musclecnt;
%         resstring{lastidx+idx} = sprintf('  %-14s %-7s %s',results.EI.muscle{idx}.name, results.EI.muscle{idx}.side,  num2str(results.EI.muscle{idx}.value,3));
%     end
%     resstring{lastidx+idx+2} = ' Fasciculaties:';
%     lastidx = lastidx + idx+2;
%     musclecnt = size(results.fasc.muscle,2)
%     for idx = 1:musclecnt;
%         resstring{lastidx+idx} = sprintf('  %-14s %-7s %s',results.fasc.muscle{idx}.name, results.fasc.muscle{idx}.side,  num2str(results.fasc.muscle{idx}.value,3));
%     end

    resstring = formatEIresults(results);
end
set(handles.echoresults,'string',resstring);
% UIWAIT makes showechoresultspopup wait for user response (see UIRESUME)
%uiwait(handles.EIresults);


% --- Outputs from this function are returned to the command line.
function varargout = showechoresultspopup_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT); 
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in OK.
function OK_Callback(hObject, eventdata, handles)
% hObject    handle to OK (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(handles.EIresults);

function [inputstring]  = formatstring(inputstring, charsize)
    numcharact = length(inputstring);
    for idx = numcharact+1:charsize
        inputstring(idx) = ' ';
    end;

function [ restext ] = formatEIresults(ud)
    restext=[];
    for i=1:length(ud.analyzed_muscles.muscles)
        if isempty(ud.analyzed_muscles.muscles{i})
            ud.analyzed_muscles.muscles{i}='';
        end;
    end;

    m=unique(ud.analyzed_muscles.muscles);
    k=1;
    s=[];
    for i=1:length(m)
        if ~strcmp(m{i},'') 
            mi=strcmp(ud.analyzed_muscles.muscles,m{i});
            ri=strcmp(ud.analyzed_muscles.sides,'R');
            idx=find((mi&ri)>0);
            if ~isempty(idx)&&max(idx)<=length(ud.analyzed_muscles.meanroi)
                if ~isempty(nonzeros(ud.analyzed_muscles.meanroi(idx)))
                    if ~isempty(ud.analyzed_muscles.muscles(i))
                        c=1;
                        meanroistr=[];
                        for x=1:length(idx)
                            if ud.analyzed_muscles.meanroi(idx(x)) ~= 0 && ~isnan(ud.analyzed_muscles.meanroi(idx(x))) %  2014-04-28 GW added: && ~isnan(ud.analyzed_muscles.meanroi(idx(i)))
                                meanroistr{c} = sprintf(' %2.0f |',ud.analyzed_muscles.meanroi(idx(x)));
                                c=c+1;
                            end
                        end
                        if ~isempty(meanroistr)
                            restext{k} = [sprintf(' %-20s | %-1s |',ud.analyzed_muscles.muscles{idx(1)}, ud.analyzed_muscles.sides{idx(1)}) meanroistr{:}] ;
                            k=k+1;
                        end
                    end
                end
            end
            li=strcmp(ud.analyzed_muscles.sides,'L');
            idx=find((mi&li)>0);
            if ~isempty(idx)&&max(idx)<=length(ud.analyzed_muscles.meanroi)
                if ~isempty(nonzeros(ud.analyzed_muscles.meanroi(idx)))
                    if ~isempty(ud.analyzed_muscles.muscles(i))
                        c=1;
                        meanroistr=[];
                        for x=1:length(idx)
                            if ud.analyzed_muscles.meanroi(idx(x)) ~= 0 && ~isnan(ud.analyzed_muscles.meanroi(idx(x))) %  2014-04-28 GW added: && ~isnan(ud.analyzed_muscles.meanroi(idx(i)))
                                meanroistr{c} = sprintf(' %2.0f |',ud.analyzed_muscles.meanroi(idx(x)));
                                c=c+1;
                            end
                        end
                        if ~isempty(meanroistr)
                            restext{k} = [sprintf(' %-20s | %-1s |',ud.analyzed_muscles.muscles{idx(1)}, ud.analyzed_muscles.sides{idx(1)}) meanroistr{:}] ;
                            k=k+1;
                        end
                    end
                end
            end
        end
    end
    restext = sort(restext);

