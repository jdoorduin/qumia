function r=getzscores(ud)
%% Changelog

%#function fitlm

%% Creëer lokale variabelen
try
    fid=fopen(fullfile(ud.qumia_path,'qumia.ini'));
catch
    fid=fopen('\\umcczzoknf01\Data_knf\Qumia_config\qumia.ini');
end
ud.musclestruct.model.modelnr_ei=str2double(inigetvalue(fid,'FILE','modelnr_ei',[]));
ud.musclestruct.model.modelnr_thickness=str2double(inigetvalue(fid,'FILE','modelnr_thickness',[]));
fclose(fid);

muscle_patient  = ud.analyzed_muscles.muscles;           % gekozen namen
roi_patient = ud.analyzed_muscles.meanroi;           % berekende uncorrected EI
thickness_patient = ud.analyzed_muscles.musclediam;      % dikte
side_patient = ud.analyzed_muscles.sides;             % gekozen kant

sex=ud.patient.geslacht;
age=ud.patient.leeftijd;
weight=ud.patient.gewicht;
ptlength = ud.patient.lengte; 
dom_side = ud.patient.kant;  

muscle_model_thickness = ud.musclestruct.model.thickness;
muscle_model_EI = ud.musclestruct.model.ei;

string_idx=[];
for i=1:length(muscle_patient)
    musclekeys{i} = ud.musclestruct.key(find(strcmp(ud.musclestruct.name,muscle_patient{i})==1));
    if isstr(muscle_patient{i})
        string_idx = [string_idx i];
    end
end
unique_muscle= unique(muscle_patient(string_idx));    % unique fieldnames

side_index(:,1) = strcmp(side_patient,'L');
side_index(:,2) = strcmp(side_patient,'R');
EI_index = roi_patient>0;
thickness_index = thickness_patient>0;

cnt=1;
for i=1:length(unique_muscle)
    muscle_index=strcmp(muscle_patient,unique_muscle{i});
    
    for side=[1 2]
        
        if side==1; muscle_side = 'L'; else muscle_side = 'R'; end
        idx_EI=find((muscle_index & side_index(:,side) & EI_index)>0);
        idx_thick=find((muscle_index & side_index(:,side) & thickness_index)>0);
        
        if strcmpi(dom_side(1),muscle_side(1))==1
            dominance = 'Dominant';
        else
            dominance = 'Non-dominant';
        end
        
        if strcmpi(sex(1),'M')==1
            sex = 'Male';
        else
            sex = 'Female';
        end
        
        %%EI
        if ud.musclestruct.model.modelnr_ei > 0
            idx_model_EI = find(strcmp([muscle_model_EI{:,1}],unique_muscle{i})==1);
        else
            idx_model_EI = [];
        end
        
        if ~isempty(idx_EI)
            if ~isempty(idx_model_EI)
                mean_roi_muscle = round(mean(roi_patient(idx_EI)));
                r.metingen.muscle{cnt}.EI=mean_roi_muscle;
                if ~isempty(idx_thick)
                    fatlayer_muscle =ud.analyzed_muscles.fatlayer(idx_thick);
                    r.metingen.muscle{cnt}.subc=fatlayer_muscle;
                else
                    fatlayer_muscle=NaN;
                    r.metingen.muscle{cnt}.subc=NaN;
                end
                
                model_input = table(nominal(dominance),nominal(sex),age,weight,ptlength,weight/((ptlength/100)^2),...
                    'VariableNames',{'Dominance' 'Sex' 'Age' 'Weight' 'Lenght' 'BMI'});
                mdl=muscle_model_EI{idx_model_EI,ud.musclestruct.model.modelnr_ei+1};
                alpha=0.05;
                [normal bounds] = predict(mdl,table2dataset(model_input),'Prediction','observation','alpha',alpha);
                t_value=tinv(1-(alpha/2),mdl.DFE);
                upper_bound = bounds(2);
                margin_error = upper_bound-normal;
                SE = margin_error/t_value;
                Zscore = (mean_roi_muscle-normal)/SE;
                
                if isnan(Zscore)
                    r.metingen.muscle{cnt}.validnormal=0;
                else
                    r.metingen.muscle{cnt}.validnormal=1;
                end
                r.metingen.muscle{cnt}.EIzscore=Zscore;
                r.metingen.muscle{cnt}.normal=normal;
                r.number_zscores(cnt)= 1;
            else
                mean_roi_muscle = round(mean(roi_patient(idx_EI)));
                r.metingen.muscle{cnt}.EI=mean_roi_muscle;
                r.metingen.muscle{cnt}.EIzscore=NaN;
                r.metingen.muscle{cnt}.normal=NaN;
                r.metingen.muscle{cnt}.validnormal=0;
                r.number_zscores(cnt)= 0;
            end
        end
        
        %%thickness
        if ud.musclestruct.model.modelnr_thickness > 0
            idx_model_thick = find(strcmp([muscle_model_thickness{:,1}],unique_muscle{i})==1);
        else
            idx_model_thick = [];
        end
        
        if ~isempty(idx_thick)
            if ~isempty(idx_model_thick)
                thickness_muscle = thickness_patient(idx_thick);
                r.metingen.muscle{cnt}.diam=thickness_muscle;
                fatlayer_muscle =ud.analyzed_muscles.fatlayer(idx_thick);
                r.metingen.muscle{cnt}.subc=fatlayer_muscle;
                
                model_input = table(nominal(dominance),nominal(sex),age,weight,ptlength,weight/((ptlength/100)^2),...
                    'VariableNames',{'Dominance' 'Sex' 'Age' 'Weight' 'Lenght' 'BMI'});
                mdl=muscle_model_thickness{idx_model_thick,ud.musclestruct.model.modelnr_thickness+1};
                
                alpha=0.05;
                [normal bounds] = predict(mdl,table2dataset(model_input),'Prediction','observation','alpha',alpha);
                t_value=tinv(1-(alpha/2),mdl.DFE);
                upper_bound = bounds(2);
                margin_error = upper_bound-normal;
                SE = margin_error/t_value;
                Zscore = (thickness_muscle-normal)/SE;
                
                r.metingen.muscle{cnt}.diamzscore=Zscore;
                r.metingen.muscle{cnt}.diamnormal=normal;
                
                if isfield(r.metingen.muscle{cnt},'validnormal')
                    if r.metingen.muscle{cnt}.validnormal==0
                        r.metingen.muscle{cnt}.validnormal=0;
                    end
                else
                    r.metingen.muscle{cnt}.validnormal=1;
                end
                
            else
                thickness_muscle = thickness_patient(idx_thick);
                r.metingen.muscle{cnt}.diam=thickness_muscle;
                fatlayer_muscle =ud.analyzed_muscles.fatlayer(idx_thick);
                r.metingen.muscle{cnt}.subc=fatlayer_muscle;
                r.metingen.muscle{cnt}.diamzscore=NaN;
                r.metingen.muscle{cnt}.diamnormal=NaN;
                
                if ~isfield(r.metingen.muscle{cnt},'validnormal')
                    r.metingen.muscle{cnt}.validnormal=1;
                end
            end
        end
        
        if ~isempty(idx_EI) ||  ~isempty(idx_thick)
            
            
            r.metingen.muscle{cnt}.name=unique_muscle{i};
            r.metingen.muscle{cnt}.side=muscle_side;
            r.metingen.muscle{cnt}.musclekey=musclekeys{i};
            
            cnt=cnt+1;
            
        end
    end
    
end

cnt=cnt-1;
if isfield(ud.analyzed_muscles,'fasc') && isfield(ud.analyzed_muscles.fasc,'key') && ~isempty(ud.analyzed_muscles.fasc.key)
    for i=1:length(ud.analyzed_muscles.fasc.value)
        % fasciculation
        if isfield(ud.analyzed_muscles,'fasc')
            if ~isempty(ud.analyzed_muscles.fasc.name{i})
                r.metingen.muscle{cnt+i}.name=ud.analyzed_muscles.fasc.name{i};
                r.metingen.muscle{cnt+i}.musclekey=ud.analyzed_muscles.fasc.key(i);
                r.metingen.muscle{cnt+i}.side=upper(ud.analyzed_muscles.fasc.side{i});
                r.metingen.muscle{cnt+i}.fasc=ud.analyzed_muscles.fasc.value(i);
            end;
        end;
    end;
end;

r.patient=ud.patient;
r.laborant=ud.laborant;
