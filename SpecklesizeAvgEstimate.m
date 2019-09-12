% Compute SpeckleSize [mm] via Inverse Fourier Transform from the Powespectrum 
% (AutoCovariance Function)
%
% Syntax:
% [Cov,Ax,Lat] = ComputeSpeckleSize(data,gamma,px_per_cm,FileName,figures,Store)
% 
% Input:
%   Required Parameters:    
%       data        -   2D data (Region of Interest LOG-data)
%                           (Selected ROI from Clinical/Simulated Image)
%       gamma       -   graylevels per dB (+/-4 if graylevel range is 0-255)
%                           (if Dynamic Range is 60: gamma = 255/60 = 4.25)
%       px_per_cm   -   Number of pixels per centimeter
%
%   Optional Parameters:
%       FileName    -   Filename for saving the plot
%       figures     -   1 = show figure   
%                       0 = no figure
%       Store       -   1 = Save Figure
%                   -   0 = do not save figure
%
% Output:
%       Cov         -   2D Powerspectrum from input data
%       Ax          -   Axial -6dB SpeckleSize [mm]
%       Lat         -   Lateral -6dB SpeckleSize [mm]

function [SpAx,SpLat,method,Cov] = SpecklesizeAvgEstimate(data,roi,gamma,mm_per_px_lat,mm_per_px_ax,Figures)

SpAx=[]; SpLat=[]; method=[]; Cov=[];               % inits

% data conditioning
data = data / gamma;                                % Echo level in dB instead of gr.lvl

data = 10.^(data/20);                               % Transform logaritmic data to linear domain     
data(roi==0) = mean(data(roi>0));                   % give excluded tissue average ROI value

FFT     = fft2(data);
[h,w]   = size(FFT);                      
N       = h * w;                                    % Number of datapoints
POW2D   = (FFT.*conj(FFT)) / N;                     % Calculate (normalized) Power Spectrum
Cov     = ifftn(POW2D);                             % Inverse Fast Fourier (Autocorrelation)
Cov     = fftshift(Cov);                            % Shift cov peak to centrer
Cov     = Cov - min(Cov(:));                        % substract DC component (first value of Cov)

Cov = 20 * log10(abs(Cov)+0.001);                   % Transform back to Log data

%% Determine 0-level (average of first (left & right) zero crossings of first derivative levels)
[y,x] = find(Cov == max(Cov(:)),1);                 % max coordinate
ax = Cov(:,x)';                                     % Axial (more noisier curve)
diff1 = diff(ax);                                   % Axial first derivative
y1 = find(diff1(y:end)>0,1,'first');                % Right side
y2 = find(fliplr(diff1(1:y-1))<0,1,'first');        % Left side
ZeroLevel = mean([ax(y+y1) ax(y-y2)]);

Peak            = max(Cov(:));                      % peak value
[y,x]           = find(Cov == Peak,1);              % peak coordinates
AxialLine       = Cov(:,x);                         
LateralLine     = Cov(y,:);

fwhm            = 6;                                % (LOG) FWHM = -6dB
hm              = (Peak - ZeroLevel) / 2;           % (LIN) Half maximum (starting at first dip before and after peak)

if Peak > 8
    min6dB = Peak - fwhm;
    method = 'LOG_FWHM';
    value = fwhm;
else
    min6dB = Peak - hm;
    method = 'LOG_HM';
    value = hm;
end
    
[SpAx,  SpAx_Px]  = SpeckleSize(AxialLine,    value, mm_per_px_ax);
[SpLat, SpLat_Px] = SpeckleSize(LateralLine', value, mm_per_px_lat);

% if SpAx > SpLat
%     figure, imagesc(Cov), colormap(gray)
%     uiwait(msgbox('Axial > Lateral: possibly ROI poistioning error! Redraw ROI and avoid depth ruler or other dominant image features!)'))
%     SpAx = []; SpLat = [];
%     return
% end

Ax_x            = (-y+1:h-y) * mm_per_px_ax;
Lat_x           = (-x+1:w-x) * mm_per_px_lat;
Ax_y            = ones(1,length(Ax_x)) * min6dB;
Lat_y           = ones(1,length(Lat_x))* min6dB;

Ax_m6dB_x       = [-SpAx/2 SpAx/2];
Ax_m6dB_y       = [min6dB min6dB];
Lat_m6dB_x      = [-SpLat/2 SpLat/2];
Lat_m6dB_y      = [min6dB min6dB];

if Figures
    hf = findobj('tag','speckle');
    if isempty(hf)
        figure('tag','speckle'), hold off
    else
        figure(hf)
        hold off
    end
    p0 = get(0,'screensize');
    set(gcf,'position',[p0(3)-580 p0(4)-750 550 650])
    
    subplot(2,1,1)
    hw = round((SpLat * 3) / mm_per_px_lat);                                % half window size for visualisation
    hh = round((SpAx * 5) / mm_per_px_ax);                                  % half window size for visualisation
    if hh > size(Cov,1)/3 || hw>size(Cov,2)/3
        imagesc(Cov)
    else
        imagesc(Cov(y-hh:y+hh,x-hw:x+hw))                                       % zoomed ACVF
    end
    colormap('gray'), colorbar, axis image                                  
    title(['AVG speckle size (',strrep(method,'_','-'),')'])
    
    subplot(2,1,2)
    plot(Ax_x, AxialLine,'-r.'), hold on                                                            % Axial AutoCovariance Line
    plot(Lat_x, LateralLine,'-k.')                                                                  % Lateral AutoCovariance Line
    plot(Ax_x, Ax_y,':r')                                                                           % Axial -6dB line
    plot(Ax_m6dB_x,Ax_m6dB_y,'or','MarkerSize',8,'MarkerFaceColor','r','MarkerEdgeColor','k')       % Axial -6dB Markers
    plot(Lat_m6dB_x,Lat_m6dB_y,'ok','MarkerSize',8,'MarkerFaceColor','k','MarkerEdgeColor','r')     % Lateral -6dB Marker
    hl = legend(sprintf('Ax:%2.3f',SpAx*10),sprintf('Lat:%2.3f',SpLat*10),strrep(method,'_','-'),'Location','NorthEast');
    set(hl,'FontSize',6)
    set(gca,'xlim',[-0.5 0.5]), grid on
    xlabel('width [mm]','FontSize',12,'FontWeight','bold')
    ylabel('Echo Level [dB]','FontSize',12,'FontWeight','bold')    
    title(['avg speckle size curves (',strrep(method,'_','-'),')'])
    
%     if Store && ~isempty(Filename)
%         print(gcf,'-dtiff','-r300',[Filename,'_SpeckleSizeCurves.tif'])
%         saveas(gcf,[Filename,'_SpeckleSiezCurves.fig'])
%     end
end

