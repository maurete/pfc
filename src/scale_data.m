function [scaled, factor, offset] = scale_data ( data, factor, offset )
%% Dataset scaling function
%
% [scaled, factor, offset] = scale_data( data )
% (for training) normalizes each column of data to the range [0,1].
%
% [scaled] = scale_data( data, factor, offset )
% (for testing) scales each column of data according factor and offset.
%

    % number of columns
    n = size(data,2);

    div = max(data)-min(data);
    for i=1:size(div,2)
        if div(i) == 0
            div(i) = 1;
        end
    end

    % compute factor if not given
    if nargin == 1
        factor = 1./(div);
    end

    % scale the data
    scaled = data*diag(factor(1:n));

    % compute offset if not given
    if nargin == 1
        offset = -min(scaled);
    end

    % apply offset
    for i=1:n
        scaled(:,i) = scaled(:,i)+offset(i);
    end

end