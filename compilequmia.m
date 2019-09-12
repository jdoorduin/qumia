%% compile script qumia
% script must start in qumia directory

%%
fprintf('Building qumia.....\n');

%source_support = 'G:\';
destination = 'G:\'; 

addpath('G:\2. Kliniek\Spierecho\QUMIA\Source_code_3.0_model\');

eval(['mcc -e qumia.m '...        
           '-R ''-logfile,qumia_log.txt'' '...
           '-R -startmsg '...
           '-d ' destination ' '...
           '-o qumia '...
           '-a front.bmp '... 
           '-a back.bmp '...
           '-a qumiastyle.xsl '... 
           '-a ''Quick manual qumia.pdf''']);
       
%copyfile('qumia_config_path.ini',destination);
%copyfile([source_support 'qumia.ico'],destination); 

delete([destination 'mccExcludedFiles.log'])
    
fprintf('Ready.....');