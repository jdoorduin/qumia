function value = inigetvalue(hndl,appname,keyname,default,rewind)
% INIGETVALUE  Gets a value from a *.ini file
%
% value = INIGETVALUE(hndl,appname,keyname,default)
% or
% value = INIGETVALUE(hndl,appname,keyname,default,rewind)
%
%   This function returns a value from a *.INI file, if this value is
%   not found the default is returned
% 
%       hndl      : handle to the open file (fid)
%       appname   : the application name (name between [])
%       keyname   : the name of the key
%       default   : the value that is used, if not found
%       rewind    : 0 = no rewind
%                   1 = rewind
%                   if this argument is ommited, file is searched from the 
%                   current file pointer's position
%
%   Note : use the rewind flag with care. It doesn't check the appname !!!   

% (c) Copyright UMC Nijmegen, by Jan Menssen
%
% $Revision: 1.1 $ $Date: 2011/12/19 16:15:49 $    

  value             = default;
  NextAppNameFound  = 0;
  KeyNameFound      = 0;
  line              = [];
  
  % check the number of arguments, if only 4 arguments are given, the rewind
  % flag is set
  
  if (nargin == 4) rewind = 1; end;
  
  try 
    
    % check rewind, if rewind is set also the appname must be found again
   
    if (rewind) 
      
      frewind(hndl);
  
      % find the application name
  
      while ((feof(hndl) ~= 1) && (IsAppName(line,appname) ~= 1))
        line = fgetl(hndl);
      end
  
    end
    
    % find the keyname, read the value and convert it to same type as the 
    % type of the default
  
    while ((feof(hndl) ~= 1) && (NextAppNameFound ~= 1) && (KeyNameFound ~= 1)) 
      line = fgetl(hndl);
      KeyNameFound = IsKeyName(line,keyname);
      if (KeyNameFound == 1)
        value = GetKeyValue(line,default);
      else
        NextAppNameFound = IsAppName(line);
      end
    end
  
  % handle the errors
  
  catch
    value = default;
  end
  
  % end of <IniGetValue>

  
% IsAppName
%
%   this function returns 1 if <line> is an application name, e.g. contains the 
%   brackets [ .. ]. If the optional argument <name> it also given, it returns only
%   true if the appname is equal to <name>

function value = IsAppName(line,name)
 
  OPEN_BRACKET  = '[';
  CLOSE_BRACKET = ']';
  value = 0;
 
  indx_open = findstr(line,OPEN_BRACKET);
  indx_close = findstr(line,CLOSE_BRACKET);
  
  if ((isempty(indx_open) == 0) && (isempty(indx_close) == 0))
    if (nargin == 1)
      value = 1;
    else  
      line = line(indx_open:indx_close);
      value = strcmp(upper([OPEN_BRACKET name CLOSE_BRACKET]),upper(line));
    end
  end
  
% end of <IsAppName>


% IsKeyName
%
%   this function returns 1 if the <line> contains the keyvalue. This is done
%   by comparing the non-space characters for the = sign with the keyname

function value = IsKeyName(line,keyname)
  
  value = 0;
  
  equal_sign_position = strfind(line,'=');
  if (isempty(equal_sign_position) == 0)
    line = deblank(line(1:equal_sign_position-1));
    value = strcmp(upper(line),upper(keyname)); 
  end  
  
% end of <IsKeyName>


% 
% GetKeyValue
%
%   this function returns the key-value of the line read

function value = GetKeyValue(line,default)

  TAB   = char(9);
  SPACE = char(32);
  
  pos = strfind(line,'=') + 1;
  while ((line(pos) == TAB) || (line(pos) == SPACE))
    pos = pos+1;
  end  
  
  value = line(pos:end);
  
  if ((isempty(default) == 0) && (isnumeric(default) == 1))
    value = str2num(value);
    if (isempty(value) == 1) value = default; end;
  end  

% end of <GetKeyValue>


