function [Icorr FatMask AvgFatThick fat] = CorrectFatAttenuation(I,fatborder,roi,roi_red,cal,Att,Fc,gamma,method)

ROI = zeros(size(I));
ROI(roi(2,1):roi(2,3),roi(1,1):roi(1,2)) = 1;           % DATA ROI

Ix = 1:size(I,2);                                       % Image X-value
% fatborder = ud.fatcontour{ud.currentfile};
x = fatborder(:,1);
y = fatborder(:,2);

switch method
    case 'manual'
        Ifit = roi_red(1,1):roi_red(1,2);
        border = interp1(x, y, Ifit, 'spline', 'extrap');   % Border Y-values (px)
        leftpart = ones(1,roi_red(1,1))*TB(roi_red(1,1));
        rightpart = ones(1,size(I,2)-roi_red(1,2)-1)*TB(roi_red(1,2));

    case 'auto'
%         Turn off warning P = polyfit(x,y,N)
        warning off MATLAB:polyfit:RepeatedPointsOrRescale
        
        Fit = polyfit(x,y,5);                           % Parabolic fit through top of ROI
        border = polyval(Fit,x)';
        
        leftpart = ones(1,x(1))*border(1);
        rightpart = ones(1,size(I,2)-x(end)-1)*border(end);
end
TissueBorder = [leftpart border rightpart]; 

fat = [Ix(roi(1,1):roi(1,2))' TissueBorder(roi(1,1):roi(1,2))']; % Fat contour limited to ROI width

TopLine = ones(1,size(I,2)) .* double(roi(2,1));        % Top of Sector (px)

% Thickness of combined fat/skin/subcut.fat layer (fatlayer)
FatLayerThick = (TissueBorder - TopLine) * cal.PhysicalDeltaY;  % [cm]
AvgFatThick = mean(FatLayerThick(roi(1,1):roi(1,2)));   % AVG THICK FROM ROI DATA[cm]

depth = ones(size(I,1),1);                              % depth curve
AttValues = FatLayerThick * Att * Fc;                   % dB.cm.MHz (dB value)
AttValues = AttValues * gamma;                          % Gray level values
AttMask = depth * AttValues;                            % Correction MASK per column
    
% Estimate Tissue ROI
TissueROI = zeros(size(I));
TissueBorder = round(TissueBorder);
TissueBorder(TissueBorder>size(I,1))=size(I,1);         % Limit contour to max depth (due te extrap it may go down image height...)
TissueBorder(TissueBorder<1)=1;                         % Limit contour to top of image
for n=1:length(TissueBorder)
    TissueROI(TissueBorder(n):end,n) = 1;
end

FatMask = double(AttMask .* TissueROI .* ROI);          % Correction mask for echo roi data only                        
Icorr = round(double(I) + FatMask);                     % echo roi data corrected image

%figure, imagesc(Icorr),hold on, plot(TissueBorder)