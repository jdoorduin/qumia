% This function resamples a given vector to a given number of samples
%
% NewLine = MyReample(line, samples)
%
% Input:
% line     - Line(vector) to resample 
% sample   - number of samples for resampling
%
% Output:
% NewLine  - Resampled line

function Resampled = MyResample(Vector,samples);

x = [1:length(Vector)];                                         % Creata original length vector
x_resample  = linspace(1,length(Vector),samples);               % Generate linearly spaced vector
Resampled   = interp1(x,Vector,x_resample,'pchip','extrap');    % Resample(interpolate) to the new vector length
