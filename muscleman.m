function [width height] = muscleman(varargin)
% [width height] = muscleman(struct, datafield, legendtext, musclestruct)
%
% Displays a body containg on both side 7 muscles. The color of the muscle reprecents a
% measured value.
%
%   input:
%       Struct is a struct containing cells with the folowing struct:
%           r.metingen.muscle{idx}.
%           name: {1x.. cell}   contains predefined name
%           side: {1x.. cell}   contains the side either left or right
%           data: {1x.. cell}   contains scaled value possible 1 ... 7
%
%       datafield:    holds the name of the field containing scaled values
%       legendtext:   is a cell array containg names for the scale steps legend
%       musclestruct: contains musclename, key and position to fill area
%
%   output:
%       width:        is the image width
%       height:       is the image height
% 
% (c) UMC Nijmegen, by Hans Tuinenga
% $Revision: 1.11 $ $Date: 2010/02/15 10:49:02 $

%% set variables
if nargin == 2
    struct = varargin{1};
    datafield = varargin{2};
elseif nargin == 4
    struct = varargin{1};
    datafield = varargin{2};
    legendvals = varargin{3};
    musclestruct = varargin{4};
end

%% Load picture with the right colormap and aspect ratio
[pict, map]= imread('front.bmp');
[pict2, map]= imread('back.bmp');
pict=[pict pict2];
imagesc(pict)
colormap(map);
daspect([1 1 1]);
width = size(pict,2);
height = size(pict,1);
set(gca,'visible','off');

if nargin == 4; muscleBar(legendvals, height); end;
%muscleBar(7,{'<1.5' '\geq1.5\leq2' '\geq2\leq2.5' '\geq2.5\leq3' '\geq3\leq3.5' '\geq3.5\leq4' '>4.5'});
%% Muscle coordinates
%{'Biceps','Quadriceps','Tib. anterior','Flex. onderarm','Ext. onderarm','Sterno cleido','Masseter';}
%biceps 1
% spier.bicepsl = [189,176;191,178;193,183;196,191;198,198;199,202;199,209;198,216;197,224;195,228;190,224;188,220;186,212;186,205;186,196;186,190;187,184;];
% spier.bicepsr = mirror(spier.bicepsl);
% 
% %quadriceps 2
% spier.quadricepsl = [150,323;155,314;165,315;170,323;172,341;170,368;159,397;147,410;147,410;143,408;142,359;144,338]; %quadriceps
% spier.quadricepsr = mirror(spier.quadricepsl);
% 
% %Tib. anterior 3
% spier.tibialisl = [151,506;152,501;154,492;157,482;159,470;160,458;159,450;154,446;151,450;148,462;147,473;148,491;149,505;];
% spier.tibialisr = mirror(spier.tibialisl);
% 
% %Flex. onderarm 4
% spier.flexonderarml = [195,235;202,240;206,244;208,248;211,253;213,261;214,274;214,283;214,289;213,292;211,292;207,290;203,280;199,267;195,251;195,243;];
% spier.flexonderarmr = mirror(spier.flexonderarml);
% 
% %Flex. onderarm 5
% spier.extonderarml = [215,226;218,231;222,237;223,241;224,249;226,258;227,267;226,279;232,266;233,253;232,244;229,236;223,229;];
% spier.extonderarmr = mirror(spier.extonderarml);
% 
% % Sternocleidomastoidius
% spier.sternocleidol = [149,107;148,117;136,139;135,119;];
% spier.sternocleidor = mirror(spier.sternocleidol);
% 
% %masseter
% spier.masseterl = [152,80;151,94;143,104;143,87;];
% spier.masseterr = mirror(spier.masseterl);

%% Draw Muscles

%keys=[musclestruct.key];
for n = 1:length(struct.muscle)
    muscle = struct.muscle{n}.name;
    if ~isempty(struct.muscle{n}.side);
        side = char(struct.muscle{n}.side);
        side = upper(side);
    else
        side = '';
    end
    if isfield(struct.muscle{1,n},datafield)
        data = cell2mat(getfield(struct.muscle{1,n},datafield));% get data from struct and change it to matrix data
    else
        data = '';
    end 
    
    if ~isempty(data)
        idx = find(strcmp(musclestruct.name,muscle)==1);  % index of current musclekey
        pFL = char(strrep(musclestruct.posFL(idx),',',';'));    % get corresponding positions
        pFR = char(strrep(musclestruct.posFR(idx),',',';'));    % get corresponding positions
        pBL = char(strrep(musclestruct.posBL(idx),',',';'));    % get corresponding positions
        pBR = char(strrep(musclestruct.posBR(idx),',',';'));    % get corresponding positions
        
        % create double arrays from position strings
        if ~isempty(pFL), eval(['pFL=',pFL,';']); else pFL=[]; end
        if ~isempty(pFR), eval(['pFR=',pFR,';']); else pFR=[]; end
        if ~isempty(pBL), eval(['pBL=',pBL,';']); else pBL=[]; end
        if ~isempty(pBR), eval(['pBR=',pBR,';']); else pBR=[]; end
        
        if strcmp(side,'L')
            if ~isempty(pFL)
                patch(pFL(:,1),pFL(:,2),clr(data));
            elseif ~isempty(pBL)
                patch(pBL(:,1)+272,pBL(:,2),clr(data));
            end
        else
            if ~isempty(pFR)
                patch(pFR(:,1),pFR(:,2),clr(data));
            elseif ~isempty(pBR)
                patch(pBR(:,1)+272,pBR(:,2),clr(data));
            end
        end
    end
end
        
%% Sub function calculate color
function res = clr(val) 
if ~isnan(val)   
    res =  [1-(1/7*val) 1-(1/7*val) 1-(1/7*val)];
else
    res = 1;
end;
   %if res+1 > 1;error('color error in muscleman'); res=0;end;
   
%% Sub function Mirror muscle coordinates
function res = mirror(val)
    res(:,1) = val(:,1)-2*(val(:,1)-131); 
    res(:,2) = val(:,2);
     
%% Sub function musclebar
function muscleBar(legendvals, height)
startpos = height - (size(legendvals,2)*25 - 5 + 20);%(aantal*hoogte - 1 tussenruimte + marge)
if isstruct(legendvals)
    for i=1:size(legendvals,2);
        clrs = legendvals(i).color;
        txt = legendvals(i).name;
        patch(250+[5,5,20,20],25*(i-1)+startpos+[5,20,20,5],clr(clrs));
        text(250+25,startpos+25*(i-1)+12,txt,'FontSize',8);
    end
else if isvector(legendvals)
        for i=1:size(legendvals,2);
            clrs = i-1;
            txt = legendvals(i);
            patch(250+[5,5,20,20],25*(i-1)+startpos+[5,20,20,5],clr(clrs));
            text(250+25,startpos+25*(i-1)+12,txt,'FontSize',8);
        end
    end    
end