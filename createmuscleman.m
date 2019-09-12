%% function createmuscleman(datastruct, type, path, musclestruct) 
%createmuscleman(fasc, zscore, path, musclestruct)
% 
% creates and saves the zscore and fasciculation muscleman
% (c) UMC Nijmegen, by Hans Tuinenga
% $Revision: 1.14 $ $Date: 2010/02/15 10:47:56 $
% 
%   input:  datastruct:
%             r.metingen.muscle{1}:
% 
%               name: 'Biceps'
%               side: 'Links' 
%               EI: 39.7137
%               EInormal: 51.3697
%               EIzscore: -2.1426
%               fasc: {[2]}
%
%           type: 
%               measurement type
%                 - 'zscore'
%                 - 'fasciculation'
%            
%           path:
%               path to store the muscleman pictures    
%            
%           musclestruct
%               Name, key, posFL, posFR, posBL, posBR
%               posFL : position of fill area front view left

function createmuscleman(datastruct, type, p, musclestruct)

%% save muscleman
switch lower(type)
    case 'zscore'
        legend(1).name = '<1.5';
        legend(1).color = 0;
        legend(2).name = '1.5-2.0';
        legend(2).color = 2;
        legend(3).name = '2.0-3.0';
        legend(3).color = 4;
        legend(4).name = '>3.0';
        legend(4).color = 6;
        
        savemuscleman(zscore2muscle(datastruct),'zscore', fullfile(p,['zscore','.jpg']),legend, musclestruct);
    case 'fasciculation'
        legend(1).name = 'No';
        legend(1).color = 0;
        legend(2).name = '+';
        legend(2).color = 2;
        legend(3).name = '++';
        legend(3).color = 4;
        legend(4).name = '+++';
        legend(4).color = 6;
        savemuscleman(fasc2muscle(datastruct),'fasc', fullfile(p,['fasciculations','.jpg']),legend, musclestruct);
end

%% Sub function state = savemuscleman(struct, datafield, filename, legendnames)
%Create mucle man and save as jpeg
function savemuscleman(struct, datafield, filename, legendnames, musclestruct)
h=findobj('Tag',datafield);
if isempty(h)
    if strcmp(datafield,'fasc')
        h = figure('visible','off','menubar','none','name','Fasciculations patient','numbertitle','off' );
    else
        h = figure('visible','off','menubar','none','name','Z-scores patient','numbertitle','off' );
    end;
else
    set(0,'currentFigure',h);
    clf;
end;
set(h,'Tag',datafield);
[width height] = muscleman(struct, datafield, legendnames, musclestruct);

set(gca,'units','pixels');
%set(gca,'ActivePositionProperty','position');
set(gca,'visible','off');
set(gca,'position', [ 0 0 width height]);
set(gcf,'position', [ 100 100 width-2 height-2]);

F = getframe(h);
try
    imwrite(F.cdata,filename);
catch
     error('file not saved');
end
    
%close(h);

%% Sub function zscore2muscle
% calculate value between 0 and 6 for zscore
% muscleman will display these values as grayscaled muscles
function output = zscore2muscle(zscorestruct)

for i=1:length(zscorestruct.metingen.muscle)
    
    if isfield(zscorestruct.metingen.muscle{i},'EIzscore')
        score = zscorestruct.metingen.muscle{i}.EIzscore;
        if ~isempty(score);
            if score <  1.5;                 zscorestruct.metingen.muscle{i}.zscore = {0}; end;
            if score >= 1.5 && score <  2;   zscorestruct.metingen.muscle{i}.zscore = {2}; end;
            if score >= 2   && score <= 3;   zscorestruct.metingen.muscle{i}.zscore = {4}; end
            if score >  3;                   zscorestruct.metingen.muscle{i}.zscore = {6}; end;
        end;
    else
        zscorestruct.metingen.muscle{i}.zscore = '';
    end
end;
output = zscorestruct.metingen;

%% Sub function fasc2muscle
% calculate value between 0 and 6 for zscore
% muscleman will display these values as grayscaled muscles
function output = fasc2muscle(fascstruct)
%datastruct.metingen.muscle{1}.fasc
for i=1:length(fascstruct.metingen.muscle)
    
    if isfield(fascstruct.metingen.muscle{i},'fasc')
        score = fascstruct.metingen.muscle{i}.fasc;
        if ~isempty(score);
            if score == 0;   fascstruct.metingen.muscle{i}.fasc = {0}; end;
            if score == 1;   fascstruct.metingen.muscle{i}.fasc = {2}; end;
            if score == 2;   fascstruct.metingen.muscle{i}.fasc = {4}; end
            if score == 3;   fascstruct.metingen.muscle{i}.fasc = {6}; end;
        end;
    else
        fascstruct.metingen.muscle{i}.fasc = '';
    end
end;
output = fascstruct.metingen;