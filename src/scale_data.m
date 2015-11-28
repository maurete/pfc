function [scaled, factor, offset] = scale_data ( data, factor, offset )
%SCALE_DATA normalize feature vectors for dataset
%
%  [SCALED, FACTOR, OFFSET] = SCALE_DATA(DATA) normalizes each column of DATA
%  to the range [0,1]. SCALED contains the normalized dataset, FACTOR the
%  factor to which each column has been multiplied, and OFFSET the offset
%  applied to every column after scaling.
%
%  [SCALED] = SCALE_DATA(DATA, FACTOR, OFFSET) normalizes DATA by multiplying
%  every column by the respective FACTOR element and then adding every value
%  in OFFSET to the respective column.
%
%  See also SCALE_SYM.
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
