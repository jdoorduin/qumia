function QUMIA_AVG_RESULTS(r,AvgFile,z_scores,musclestruct)

%% FIND GROUPS OF MUSCLES/SIDES
group = [];

pat = 1; % patient index
for n=1:length(r)
    if sum(sum(group==n))==0
    im = 1; % image index 
    if pat > 1
        prev = group(pat-1,:); % previous patient images
        if isempty(find(prev==n)) % Image not already in previous patient
            [group,pat] = FindSimilarImages(r,n,pat,group);
        end
    else
        [group,pat] = FindSimilarImages(r,n,pat,group);
    end
    end
end 
 
%% HEADER
%output_module 1
tags{1} = {'ID','Name','Birthdate','Lenght','Weight','Sex',...
          'Age','Dominance','Measurement date','ROI date','Technician','Muscle','Side'};
      
%output_module 2
tags{2} = {'Fat layer','Thickness','Absolute gray level','SD absolute gray level'};

%output_module 4
tags{3} = {'Zscore thickness','Zscore gray level'};

%output_module 4
tags{4} = {'Relative dB level','Relative gray level','Axial speckle size','Lateral speckle size','UTC Relative dB level','UTC RAC','UTC SD','UTC SNR'};

modules= [1 2];
if musclestruct.EI_ref_check==1 || musclestruct.thick_ref_check==1
    modules=[modules 3];
end
if sum(strcmp({r.project},'None')+cellfun('isempty', {r.project})) < length(r)
    modules=[modules 4];
end
        
selected_tags=[];
for i=modules
    selected_tags = [selected_tags tags{i}];
end

%% Estimate average results per patient muscle

a=1; 
for i=find(not(cellfun(@isempty,z_scores)))
    for j=1:length(z_scores{i}.metingen.muscle)
        if isfield(z_scores{i}.metingen.muscle{j},'EI')
            new_z_scores{a} = z_scores{i}.metingen.muscle{j};
            new_z_scores{a}.patientid = z_scores{i}.patient.patientid;
            a=a+1;         
        end
    end
end 

for p=1:size(group,1)
    resstr = '';
    
    images = group(p,:);
    images = images(images>0);
    L = length(images);
    
    pat = r(images(1)); % first of patient muscle group
    
        
        j=0;
        index_zscore=0;
        while index_zscore==0
            j=j+1;
            index_zscore = strcmp(pat.muscle,new_z_scores{j}.name)  && strcmp(pat.patientid,new_z_scores{j}.patientid) && strcmp(pat.side,new_z_scores{j}.side);
        end
        z_score_EI_muscle = new_z_scores{j}.EIzscore;
        
        if isfield(new_z_scores{j},'diam')
            musclediam = new_z_scores{j}.diam;
            fatlayer = new_z_scores{j}.subc;
            z_score_thickness_muscle = new_z_scores{j}.diamzscore;
        else
            musclediam = '';
            fatlayer = '';
            z_score_thickness_muscle = '';
        end
  
    % average values
    fat=[]; mu_or=[]; mu_dB=[]; mu_gr=[]; ax=[]; lat=[]; utc_mu=[]; utc_rac=[]; utc_sd=[]; utc_snr=[];
    for i=1:L
       fat(i) = r(images(i)).fat;
       mu_or(i) = r(images(i)).mu_uncorr;
       mu_sd(i) = r(images(i)).mu_sd;
       mu_dB(i) = r(images(i)).mu_rel_dB;
       mu_gr(i) = r(images(i)).mu_rel_gray;
       ax(i) = r(images(i)).ax;
       lat(i) = r(images(i)).lat;
       utc_mu(i) = r(images(i)).mu_rel_dB_UTC;
       utc_rac(i) = r(images(i)).mu_RAC_UTC;
       utc_sd(i) = r(images(i)).SD_mu_UTC;
       utc_snr(i) = r(images(i)).SNR_mu_UTC;
    end
    
    % mean values
    fat_mu = mean(fat);
    mu_or_mu = mean(mu_or);
    mu_sd_mu = mean(mu_sd);  
    mu_dB_mu = mean(mu_dB);
    mu_gr_mu = mean(mu_gr);
    ax_mu = mean(ax);
    lat_mu = mean(lat);
    utc_mu_mu = mean(utc_mu);
    utc_rac_mu = mean(utc_rac);
    utc_sd_mu = mean(utc_sd);
    utc_snr_mu = mean(utc_snr);
    
    selected_output_string{1}={pat.patientid,pat.patienname,pat.gebdat,...
        pat.lengte,pat.gewicht,pat.geslacht,pat.leeftijd,pat.kant,pat.meetdatum,...
        pat.roi_date,pat.laborant,pat.muscle,pat.side};
    selected_output_string{2}={fatlayer,musclediam,mu_or_mu,mu_sd_mu};
    selected_output_string{3}={z_score_thickness_muscle,z_score_EI_muscle};
    selected_output_string{4}={mu_dB_mu,mu_gr_mu,ax_mu,lat_mu,utc_mu_mu,utc_rac_mu,utc_sd_mu,utc_snr_mu};
    
    output_string = [];
    for i=modules
        output_string = [output_string selected_output_string{i}];
    end

    output_string_all(p,:) = output_string;
end

xlswrite(AvgFile,[selected_tags;output_string_all]);

