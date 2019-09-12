% Function to calculate the width of a top (SpeckleSize) of a certain FWHM
%

function [SpeckleSize_mm, SpeckleSize_Px] = SpeckleSize(data,fwhmv,mm_per_px)
    
    [Max_v,Max_i] = max(data);                                      % Peak index and value
    
    %% Left side check & px's estimation
    temp        = fliplr(data(1:Max_i)');
    FWHM        = Max_v - fwhmv;                                    % -6dB value
    r_ind       = find(temp < FWHM,1,'first');                      % First Index under -6dB Value Left side
    
    Px_left     = [];
    if ~isempty(r_ind)
        l_il        = Max_i - r_ind + 1; 
        l_ih        = l_il + 1;                                     % First Index under -6dB Value Left side
        l_i_int     = (data(l_ih)-FWHM)/(data(l_ih)-data(l_il));    % Left side FWHM linear interpolation
        Px_left     = Max_i - (l_ih - l_i_int);                     % speqles at left side
    end
    
    %% Right side check & px's estimation
    temp        = data(Max_i:end);
    l_ind       = find(temp < FWHM,1,'first');                      % Last Index above -6dB Value Right side
    
    Px_right    = [];
    if ~isempty(l_ind)
        r_ih        = Max_i-1 + l_ind-1;
        r_il        = r_ih + 1;                                     % First Index under -6dB Value Right side
        r_i_int     = (data(r_ih)-FWHM)/(data(r_ih)-data(r_il));    % Left side FWHM linear interpolation
        Px_right    = (r_ih + r_i_int) - Max_i;                     % speqles at right side
    end
    
    if ~isempty(Px_left) && ~isempty(Px_right)                      % both sides oke
        SpeckleSize_Px = Px_left + Px_right;   
    elseif isempty(Px_left) && isempty(Px_right)                    % No side oke
        SpeckleSize_Px = NaN;
        SpeckleSize_mm = NaN;
%         disp('Left & Right side error...')
        return
    elseif isempty(Px_left) && ~isempty(Px_right)                   % Only left side is oke              
        SpeckleSize_Px = Px_right * 2;
    elseif ~isempty(Px_left) && isempty(Px_right)                   % Only right side is oke
        SpeckleSize_Px = Px_left * 2;
    end
    
    SpeckleSize_mm = SpeckleSize_Px * mm_per_px;                     % SpeckleSize from pixels to milimeters