%This function computes auto and cross correlations and returns two cell
%arrays (one with the autocorrelation and one with the cross correlation).
% Y(kxT)-data matrix--series in rows and time down columns
% rowMat(1xr)- a row vector directing which rows of Y the calculation
% should be performed upon.
% maxT-number of periods for which autocorrelations should be computed
%
% auto(txr)-cell array with first order autocorellations computed (the tth
% row is the tth order autocorrelation and the rth column is the
% autocorrelation for a particular series.
% cross(rxr)-correlations across series (should be symmetric, with ones along diagonal)
function [auto cross]=autoCrossCorrel(Y, rowMat, maxT, labelArray);

i=0;
for row=rowMat;
    i=i+1;
    if nargin>3;
        lab=1;
        auto{1, i+1}=labelArray{1,i};
        
        cross{1,i+1}=labelArray{1,i};
        cross{i+1,1}=labelArray{1,i};
    end;
    %Compute autocorrelations
    for t=1:maxT;
        if nargin>3;
            auto{t+1,1}=mat2str(t);
        end;
        auto{t+lab,i+lab}=corr(Y(row, 1:size(Y,2)-t)', Y(row, 1+t:size(Y,2))'); %the +1's are because the first row is labels
    end;
    %compute cross correlations
    j=0;
    for row2=rowMat;
        j=j+1;
        cross{i+lab,j+lab}=corr(Y(row, 1:size(Y,2))', Y(row2, 1:size(Y,2))');
    end;
end;


    auto(2:t+1, :);
    cross(2:i+1, :);
