function [muscle_list] = load_excel_musclelist(musclefile)

% 06-12-2017
% Script for loading muscle list and muscle position from Excel file

%% Load muscle list from Excel file
sheet = 'Muscle list';

[numdata,txtdata,raw] = xlsread(musclefile,sheet,'','basic');
sizedata = size(raw);

columndata = struct; % Get the column names
for i = 1:sizedata(2)
    columndata(i).code = char(txtdata(2,i));
    columndata(i).type = char(txtdata(3,i));
end

muscle_list= struct;% Collect muscle data
cnt = 1;
for i = 4:sizedata(1)
    muscle_list.names{cnt,1} = txtdata{i,1};
    muscle_list.keys(cnt,1) = numdata(i,1);
    muscle_list.state(cnt,1) =  numdata(i,2);
    muscle_list.posFL{cnt,1} = txtdata{i,4};       % posFL (front left)
    muscle_list.posFR{cnt,1} = txtdata{i,5};        % posFR (font right)
    muscle_list.posBL{cnt,1} = txtdata{i,6};        % posBL (back left)
    muscle_list.posBR{cnt,1} = txtdata{i,7};        % posBR (back right)
    cnt=cnt+1;
end

