function Settings = LoadProjectSettings(file,qumia_path)

sep = ';'; eol = '\r\n';
hdr  = textread(file,'%s',1);
hdr = hdr{1};
i = strfind(hdr,sep);

% Get headernames
h{1} = hdr(1:i(1)-1);
for n=1:length(i)-1
    h{n+1} = hdr(i(n)+1:i(n+1)-1);
end
h{n+2} = hdr(i(n+1)+1:end);

% define data types
str = '';
for n=1:length(h)
    if strcmpi(h(n),'project') || ~isempty(strfind(h{n},'FLoc'))
         str = [str,'%s']; 
    else str = [str,'%f'];
    end    
end

% Read all data from file
[D{1:length(h)}] = textread(file,str,'headerlines',1,'delimiter',sep,'endofline',eol);
Settings = cell2struct(D,h,2);
for i=1:length(Settings.LUTposFLoc)
    Settings.DepthProfileFLoc{i}=fullfile(Settings.DepthProfileFLoc{i});
    Settings.LUTposFLoc{i}=fullfile(Settings.LUTposFLoc{i});
end
Settings.types = str;
Settings.header = h;
Settings.eol = eol;
Settings.sep = sep;