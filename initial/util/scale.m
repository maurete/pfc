function [scaled, factor, offset] = scale ( data, factor, offset )
% scales columns of data to fit the range (0,1)
% returns the scaled data, and vectors 'factor' and 'offset'
% to later scale new data 
    f = size(data,2);
    if nargin == 3
        scaled = data * diag(factor);
        for i=1:f
            scaled(:,i)=scaled(:,i)+offset(i);
        end
        return
    end
    
    factor = 1./(max(data)-min(data));
    scaled = data*diag(factor);
    offset = -min(scaled);
    
    for i=1:f
        scaled(:,i) = scaled(:,i)+offset(i);
    end
end