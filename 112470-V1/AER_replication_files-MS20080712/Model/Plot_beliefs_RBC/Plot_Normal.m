

function [f_n, data] = Plot_Normal(mu,sigma,data)

% data = data_range(1):data_range(2):data_range(3);

f_n = zeros(length(data),1);

for ctn = 1:length(data)
    
    f_n(ctn) = (1/(sigma*sqrt(2*pi)))*exp(-((data(ctn)-mu)^2/(2*sigma^2)));


end