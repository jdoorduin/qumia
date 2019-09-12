function [Icorr] = LUTcorrection(I,Correction);

%corr = zeros(size(I));                       % Correction mask init.
[nrow,ncol]=size(I);
Icorr=zeros(nrow*ncol,1);

% for j = 1:nrow
%     for k = 1:ncol
%         corr(j,k) = Correction(round(I(j,k))+1);            % set the grayvalue to correct in the Mask
%         Icorr(j,k) = I(j,k) - corr(j,k);     % substract the grayvalue to correct from the ROI value
%     end
% end

for cnt=1:255
     indx=find(I==cnt-1);
     Icorr(indx)=I(indx)-Correction(cnt);
%    corr(indx)=Correction(cnt);
end;
Icorr=reshape(Icorr,nrow,ncol);
%corr=reshape(corr,nrow,ncol);

