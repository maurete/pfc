function [scaled, factor, offset] = scale_sym ( data, factor, offset )
%% Dataset scaling function
% 
% [scaled, factor, offset] = scale_data( data ) 
% (for training) normalizes each column of data to the range [-1,1].
%
% [scaled] = scale_data( data, factor, offset ) 
% (for testing) scales each column of data according factor and offset.
%

    % number of columns
    n = size(data,2); 
    
    % compute factor if not given
    if nargin == 1
        factor = 2./(max(data)-min(data));
    end
    assert( max(factor) ~= Inf, 'scale_sym: division by zero!' )
    
    % scale the data
    scaled = data*diag(factor(1:n));
    
    % compute offset if not given
    if nargin == 1
        offset = -min(scaled)-1;
    end
    
    % apply offset
    for i=1:n
        scaled(:,i) = scaled(:,i)+offset(i);
    end

end