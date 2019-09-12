function [Icorr,Iroi,Idisp,out,fat,LUT2] = convertimage_caus(qumia_path,all_PS,current_PS,I,roi,data,roi_red,dcm_roi,cal,Fig)
% CONVERTIMAGE_CAUS applies CAUS modules to IMAGE/ROI data

% $Revision: 1.11 $ $Date: 2012/05/14 13:00:37 $
% (c) UMC St Radboud by Hans van Dijk

% QA4US Esaote KNF:

% see: D:\UMCN\QA4US\DATA\Esaote MyLabTwice\LA533
% Ref0dB = 54;
% RefGamma = 4.0;

cur_depth = double((data(2,3)-data(2,2)) * double(cal.PhysicalDeltaY));

% if cur_depth > 3.5 && cur_depth < 4.5
%     id=find(strcmp('Esaote_LA533_4cm',all_PS.Project));
% elseif cur_depth > 5.5 && cur_depth < 7.5
%     id=find(strcmp('Esaote_LA533_6cm',all_PS.Project));
% else
%     id=3;
% end

if isfield(current_PS,'id')
    id=current_PS.id;
else
    id=find(strcmp('None',all_PS.Project));
end

PS.Project = all_PS.Project{id};
PS.Background = all_PS.Background(id);
PS.gamma = all_PS.gamma(id);
PS.Fc = all_PS.Fc(id);
PS.Att = all_PS.Att(id);
PS.DepthProfileFLoc = all_PS.DepthProfileFLoc{id};
PS.LUTposFLoc = all_PS.LUTposFLoc{id};

fat = [];
LUT2 = [];
out = struct('AvgFatThick',NaN,'meanroi',NaN,'meanroi_rel_dB',NaN,'SpAx',NaN,'SpLat',NaN,'SpMethod','','c',[]);

% inits
i = []; Iroi = []; Icorr = []; TissueBorder = [];
c = zeros(1,5);                 % applied correction steps
[h,w] = size(I);


if ndims(I)==3
    % Take a weighted combination of all colors (ROI data is unaffected
    % since gr.lvl are same over alle RGB layers!!!
    I = double(.2989*I(:,:,1)+.5870*I(:,:,2)+.1140*I(:,:,3));
else
    I = double(I);
end
Icorr = I;  % Init Corrected Image
Idisp = I;  % Init Corrected Image to be visualized (without beamprofile correction)


if ~isempty(roi)
    
    x = round(roi(1,:)); y = round(roi(2,:));
    ROI = roipoly(I,x,y);                       % Creat ROI MASK
    i = find(ROI>0);                            % ROI data indici
    out.meanroi = mean(I(i));                   % Mean of uncorrected roi data +6 voor AMC
    out.sdroi = std(I(i)); 
    Iroi = I(i);                                % Uncorrected ROI data
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Automatic fatlayer detection
    [row,col,v]=find(ROI==1);
    
    % Find ROI left and right start/end points
    offset = 1.3;       % offset from ROI to tissueborder [mm]
    lx = col(1);        % left x
    rx = col(end);      % right x (may be multiple)
    rxi = find(col==rx,1,'first');    % top right x
    
    % Find top curvature
    t = 1;
    Yt = zeros(1,rx-lx+1);
    for n = lx:rx % find top of ROI for every column
        Yt(t) = find(ROI(:,n)>0,1,'first'); t = t+1;
    end
    Xt = lx:rx; % corresponfing x values
    
    if isfield(cal,'PhysicalDeltaY') && ~isempty(cal.PhysicalDeltaY)
        dy = cal.PhysicalDeltaY;            % um/px
        yoffset = round(offset/(dy*10));    % pixel shift [px] of ROI to muscle-border
        Yt = Yt - yoffset;
        fat = [Xt' Yt'];                    % fat = [x y]
        
        %% Apply fat-layer correction on real ROI data only!!!
        [Icorr, FatMask, out.AvgFatThick, fat] = CorrectFatAttenuation(Icorr,fat,data,roi_red,cal,PS.Fc,PS.Att,PS.gamma,'auto');   % Correct for odd(not nomal, more of less) attenuation
        Idisp  = Icorr;
        c(4) = 1;                                % Fat Corrected image
    end
end

if ~strcmp(PS.Project,'None')
    
    %% ToDo: Apply LUT correction !!!
    if isfield(PS,'LUTposFLoc') && ~isempty(PS.LUTposFLoc)
        if exist(fullfile(qumia_path,PS.LUTposFLoc),'file')
            
             load(fullfile(qumia_path,PS.LUTposFLoc))    % loads: r, x & y LUT
            lut2D = I(r(2):r(2)+r(4),r(1):r(1)+r(3));
            lut = fliplr(mean(lut2D,2)');
            
            LUToke = 1;
            if lut(end)<250 || lut(1)>5
                LUToke = 0;
                
                % Check if different LUT position is pressent (due to DICOM layout change in 81 & 82)
                [tp,tn,te]=fileparts(fullfile(qumia_path,PS.LUTposFLoc));
                if exist([tp,'/',tn,'2',te],'file')
                    
                    LUT2 = [tp,'/',tn,'2',te];
                    load(LUT2)                      % Load different LUT position calibration
                    delete(findobj('tag','LUT'))    % Delete previous LUT position
                    if Fig % Don't plot LUT during autorecalculate
                        plot(x,y,':m','Tag','LUT2')     % Plot new LUT position
                    end
                    
                    lut2D = I(r(2):r(2)+r(4),r(1):r(1)+r(3));
                    lut = fliplr(mean(lut2D,2)');
                    max_lut = max(lut(:));
                    
                    if lut(end)<250 || lut(1)>5
                        LUToke = 0;
                    else LUToke = 1;
                    end
                end
            end
            
            if ~LUToke
                disp('error: max of LUT if < gr.lvl 250')
                disp('LUT position recalibration is possibly needed!')
            else
                lut_r = MyResample(lut,max(lut(:)));
                lut_x = 1:length(lut_r);
                warning off
                PFit = polyfit(lut_x,lut_r,7);
                warning on
                PolyFit = polyval(PFit,lut_x);
                LinearFit = 0:max(lut(:))-1;
                
                [max_lin_check,mi] = max(lut_r - LinearFit);
                mu_lin_check = mean(abs((lut_r - LinearFit)) / max(lut(:)));        % normalized abs error
                
                if ~(max_lin_check < 5 && mu_lin_check < 1)                         % not linear?
                    
                    % Update DCM ROI DATA only! (overcome visualisation errors)
                    LUTcorr = LUT_Correct(Icorr,PolyFit);                           % New updated LUT correction
                    if ~isempty(dcm_roi)
                        Icorr(dcm_roi(2,1):dcm_roi(2,3),dcm_roi(1,1):dcm_roi(1,2)) = LUTcorr(dcm_roi(2,1):dcm_roi(2,3),dcm_roi(1,1):dcm_roi(1,2));
                    else Icorr = LUTcorr;
                    end
                    Idisp = Icorr;
                end
                c(1) = 1; % is linear or corrected!

            end
        else % invalid LUT-pos file
            uiwait(msgbox({['Invalid Look Up Table position file: ',PS.LUTposFLoc],...
                'Please point out valid filename and location, or create one',...
                'One can do so via the "Config" menu'}))
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Correct Gain And Gamma by scaling the gamma_diff firstly,
    %%% then correct the resulting background intensity diff
    % figure, subplot(1,2,1),hist(Icorr(i))
    if isfield(PS,'gamma') && ~isempty(PS.gamma)
%        gamma_correction = RefGamma / PS.gamma;
%        background_correction = Ref0dB - PS.Background; % * gamma_correction;
%        GAMMA_CORR = Icorr * gamma_correction + background_correction;
        
        % replace DATA_REGION with GAIN & GAMMA corrected data
%        Icorr(data(2,1):data(2,3),data(1,1):data(1,2)) = GAMMA_CORR(data(2,1):data(2,3),data(1,1):data(1,2));
%        Idisp = Icorr;
        c(2) = 1;
        
        %% Apply beamprofile correction only if GAIN-GAMMA correction is pressent!!!
        
        %%%% TODO: 6cm width is smaller
         
        if isfield(PS,'DepthProfileFLoc') && ~isempty(PS.DepthProfileFLoc)
            if exist(fullfile(qumia_path,PS.DepthProfileFLoc),'file')
                load(fullfile(qumia_path,PS.DepthProfileFLoc));          % Load beamprofile (vars: depth, BeamProfileFit, beamprofile, FIT)
                
                diff1 = abs(cur_depth - depth);
                if diff1 > 0.5
                    oke = 0;
                    uiwait(msgbox('!!! WARNING: DEPTH OF BEAMPROFILE DIFFERS MORE THAN 0.5CM OF CURRENT IMAGE DEPTH !!!'))
                else
                    oke = 1;
                end
                
                % Correct BEAM PROFILE
                if oke
                    BEAM_MASK = zeros(size(I));
                    
                    % APPLY GAIN_GAMMA correction first! (Was not applied when calculation this curve)
                    %BeamProfileCorr = BeamProfileFit * gamma_correction + background_correction;
                    %beam_rel = BeamProfileCorr - PS.Background;                         % Correction relative to background (0dB level)
                    
                    beam_rel = BeamProfileFit - PS.Background;
                    
                    width = ones(1,(data(1,2)-data(1,1)));
                    REL_BEAM_CORR = beam_rel * width;                                   % Gr.lvl correction mask
                    [h,w] = size(REL_BEAM_CORR);
                    if data(2,2)+h-1 > size(I,1) || data(1,1)+w-1 > size(I,2)
                        uiwait(msgbox('Beamprofile correction failed! Check Config (project settings) or image settings'))
                    else
                        BEAM_MASK(data(2,2):data(2,2)+h-1,data(1,1):data(1,1)+w-1) = REL_BEAM_CORR;
                        Icorr = Icorr - BEAM_MASK;
                        Idisp = Icorr; % Corrected Figure
                        c(3) = 1;
                    end
                    %             figure, plot(beamprofile)
                    %             subplot(1,2,1)
                    %             plot(BeamProfileFit,'r'), hold on
                    %             plot(xl,[PS.Background PS.Background],':k')
                    %             subplot(1,2,2)
                    %             plot(BeamProfileFit - PS.Background)
                end
            else
                uiwait(msgbox('!!! NO BEAMPROFILE COULD BE DETECTED >> CHECK PROJECT SETTINGS (via CONFIG menu) !!!'))
            end
        end
    else
        disp({'No gamma (gr.lvl per decibel) value is pressent in the projectsettings!',...
            'One may use the QA4US software (www.qa4us) for the calibration of the equipment preset and estimation of the gamma.',...
            '(A Tissue Mimicking Phantom with contrast disks is required herefore)'})
    end
    
    % if ~isempty(roi)
    %     keyboard
    % end
    
    % %% Apply fat-layer correction on real ROI data only!!!
    % if ~isempty(fat)
    %     [Icorr, FatMask, out.AvgFatThick] = CorrectFatAttenuation(Icorr,fat,data,cal,PS.Fc,PS.Att,PS.gamma,'manual');   % Correct for odd(not nomal, more of less) attenuation
    %     Idisp  = Icorr;
    %     c(4) = 1;                               % Fat Corrected image
    % end
    
    %% In order to estimate relative gray levels [dB]:
    % - ROI must be pressent
    % - all CAUS modules must be performed sucessfully:
    %   - Fat-layer correction must be defined and corrected for
    %   - LUT-correction (Linearization)
    %   - BEAM-PROFILE correction
    %   - gamma, 0dB, Fc, att values must be known!
    %   - gamma and 0dB of reference study must be known
    if ~isempty(i) % && sum(c(1:4))==4
        if isfield(PS,'gamma') && ~isempty(PS.gamma)        % muscle roi must be pressent and CAUS modules were applied
            Icorr = (Icorr(i) - PS.Background) / PS.gamma;  % Convert 2 decibels and express relative to 0dB of reference phantom
            out.meanroi_rel_dB = mean(Icorr(:));            % Mean relative echolevel [dB]
            %         if exist('ROI','var'), disp(['Mean FINAL rel dB: ',num2str(mean(Icorr))]); end
            c(5) = 1;
        else
            Icorr = [];
        end
    else
        Icorr = [];                             % No roi: no data...
    end
    
    %% Estimate Speckle Size if ROI is pressent
    if ~isempty(i)
        hfig = gcf;     % backup gcf
        [out.SpAx,out.SpLat,out.SpMethod] = SpecklesizeAvgEstimate(I,ROI,PS.gamma,cal.PhysicalDeltaX,cal.PhysicalDeltaY,Fig);
        if get(findobj('Tag','SupportFig'),'Value')
            figure(hfig);   % switch back to current figure
        end
    end
        
end

%%
if exist('ROI','var')
    [out.UTC_MU,out.UTC_SD,out.UTC_SNR,out.UTC_depth] = UTC(Idisp,ROI,PS.gamma,PS.Background,10*cal.PhysicalDeltaY,PS.Fc,(2*0.4)/(cal.PhysicalDeltaY*10),0); %0.4 mm is axiale specklegrootte gemeten bij fantoom   
end

%%

out.c = c; % Stored applied CAUS modules / post-processing steps