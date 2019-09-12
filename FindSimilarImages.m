function [group,pat]= FindSimilarImages(r,n,pat,group)
    

% SKIP images without EI
    if isempty(r(n).mu_uncorr)
        return
    end 

    
    %% Fields:  must be equal
    id = r(n).patientid;
    mus = r(n).muscle;
    side = r(n).side; 
       
    group(pat,1) = n;
    im = 2;
    
    for p = n+1:length(r) % zoek vanaf volgende record
        id2 = r(p).patientid;
        mus2 = r(p).muscle;
        side2 = r(p).side;
        if strcmp(id,id2) && strcmp(mus,mus2) && strcmp(side,side2) % vind gelijke
            % IGNORE images with fatlayer & musclethiskness results
            %if ~(isfield(r,'fatlayer') && ~isempty(r(p).fatlayer))
            
            % IGNORE images that are empty
            if ~isempty(r(p).mu_uncorr)
                group(pat,im) = p;
                im = im + 1;
            end
         elseif ~strcmp(id,id2) % niet gelijk dan volgende patient
             pat = pat + 1;
             break
        end
        if p==length(r)
            pat = pat + 1;
        end
    end