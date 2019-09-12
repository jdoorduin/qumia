function [MU,SD,SNR,depth] = UTC(Image,ROI,gamma,background,cal_y,Fc,hh,Figures)

%RAC   estimate UltrasoundTissueCharacterics using first order parameters (MU, SD & SNR) 
%   and depth dependency of these parameters by linear fit estimates
%   
%  function:
%       [MU,SNR,SD,depth] = UTC(Image,ROI,gamma,cal_y,Fc,hh,Figures)
%
%   inputs:
%       Image   - 2D grayscale B-mode image
%       ROI     - 2D logical region of interest (0=exclude, 1=include)
%       gamma   - number of echo levels per decibel (output from QA4US software)
%       cal_y   - calibration factor describing 'mm per pixel' (found in
%                   DCM-header > info.SequenceOfUltrasoundRegions.Item_1.PhysicalDeltaY
%       Fc      - central frequency of the probe [MHz]
%       hh      - half window height [px] for movind subroi
%       Figures - (0,1) 0 = do not show line graph; 1 = show line graph
%
%   outpus:
%       MU      - mean echo level characteristics    
%       SD      - stdev of echo level characteristics
%       SNR     - Signal-to-Noise ratio characteristics
%       depth   - average/central ROI depth [mm]
% 
% By:   G.Weijers, MUSIC, gert.weijers@radboudumc.nl
% Created @ 2019-05-08
warning off

Image = (Image)/gamma;                                                      % convert echolevels into dB
MU = []; SNR = []; SD = []; ind = []; k = 1;   % inits

roi_start = find(mean(ROI,2)>0,1,'first');
roi_end = find(mean(ROI,2)>0,1,'last');

% downshift a subroi for echo level parameters estimation
if roi_start+hh>roi_end-hh % voor kleine spieren
    hh = round((roi_end-roi_start)/5)
end

for n=roi_start+hh:roi_end-hh % for every valid row of Logical Mask
    if ~isequal(ROI(n-hh:n+hh,:),zeros(size(ROI(n-hh:n+hh,:)))) % If data in BLOCK
        if k==1, start_index = n; end                                       % Start counter
        
        subROI =(double(Image(n-hh:n+hh,:)) .* double(ROI(n-hh:n+hh,:)));   % row-data of current ROI

        MU(k)       = nanmedian(subROI(subROI~=0));                           % average echo echo level
        SD(k)       = nanstd(subROI(subROI~=0));                            % standard deviation
        SNR(k)      = MU(k) / SD(k);                                        % Signal-to-Noise Ratio
        ind(k)      = n;
        k           = k + 1;
    elseif k>1 % To less valid data for Statistics estimation
        MU(k)       = NaN;
        SNR(k)      = NaN;            
        SD(k)       = NaN;
        ind(k)      = n;
        k           = k + 1;
    end
end

depth = (ind(1) + (k/2)) * cal_y;                               % Averaged ROI depth [mm]
x_px = (1:length(MU)) + start_index;                          % x [px]
d = x_px * cal_y / 10;                                          % x [cm]

% Remove NaN's
ind(isnan(SD))      = [];
d(isnan(SD))        = [];
MU(isnan(SD))       = [];
Snr(isnan(SD))      = [];
Sd(isnan(SD))       = [];

%% Linear Fit through echo level parameter profiles
% Mean echo level characteristics
warning off

MU.data             = MU;                                                  
MU.unit             = 'dB';
MU.mu               = mean(MU.data)-(background/gamma); %relative from background
MU.sd               = std(MU.data);
MU.Fit              = polyfit(d,MU.data,1);
MU.Linear           = polyval(MU.Fit,d); 
MU.RAC              = -MU.Fit(1)/Fc; % express residual atteanution coefficient (RAC) in [dB/cm/MHz]
MU.RAC_unit         = 'dB/cm/MHz';
MU.SlopeFunction    = ['y = ',sprintf('%3.2f',MU.Fit(1)),'x + ',sprintf('%3.2f',MU.Fit(2))];
MU.x                = d;
MU.ind              = ind;

% standard deviation characteristics
SD.data             = SD;
SD.unit             = 'dB';
SD.mu               = mean(SD.data);
SD.sd               = std(SD.data);
SD.Fit              = polyfit(d,SD.data,1);
SD.Linear           = polyval(SD.Fit,d);
SD.SlopeFunction    = ['y = ',sprintf('%3.2f',SD.Fit(1)),'x + ',sprintf('%3.2f',SD.Fit(2))];
SD.x                = d;
SD.ind              = ind;

% signal to noise ratio characteristics
SNR.data            = SNR;
SNR.unit            = '';
SNR.mu              = mean(SNR.data);
SNR.sd              = std(SNR.data);
SNR.Fit             = polyfit(d,SNR.data,1);
SNR.Linear          = polyval(SNR.Fit,d);
SNR.SlopeFunction   = ['y = ',sprintf('%3.2f',SNR.Fit(1)),'x + ',sprintf('%3.2f',SNR.Fit(2))];
SNR.x               = d;
SNR.ind             = ind;

qumia_fig_handle=gcf;

if Figures
    
    h_slopes = findobj('Tag','UTC');
    if isempty(h_slopes)
        figure('Name','UTC','Tag','UTC');
    else
        figure(h_slopes)
    end
    hold off
    plot(d,MU.Linear,'k','LineWidth',2), hold on
    plot(d,SD.Linear,'-b','LineWidth',2)
    plot(d,SNR.Linear,'-r','LineWidth',2)
    plot(d,MU.data,'-k','LineWidth',2)
    plot(d,SD.data,'-b','LineWidth',2)
    plot(d,SNR.data,'-r','LineWidth',2)
    hl = legend('MU [dB]','SD [dB]','SNR');
    set(hl,'FontSize',10,'Location','northeast','box','off')
    x = get(gca,'XLim');
    y = get(gca,'Ylim');
    set(gca,'FontWeight','bold')
    xlabel('depth [cm]','Fontname','Arial','FontWeight','bold','FontSize',12)
    ylabel('value','Fontname','Arial','FontWeight','bold','FontSize',12)
        
    text(min(x)+0.5,max(MU.Linear)+2,MU.SlopeFunction,  'FontSize',12,'FontWeight','bold','Color','black');
    text(min(x)+0.5,max(MU.Linear)+4,SD.SlopeFunction,   'FontSize',12,'FontWeight','bold','Color','blue');
    text(min(x)+0.5,max(MU.Linear)+6,SNR.SlopeFunction,  'FontSize',12,'FontWeight','bold','Color','red');
        
    set(gca,'YLim',[y(1)-1 y(2)+6],'XLim',[d(1)-0.5 d(end)+0.5])
    set(gca,'Fontweight','bold')
end

figure(qumia_fig_handle)
