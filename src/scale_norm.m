function [scaled, factor, offset] = scale_norm ( data, factor, offset )
%SCALE_NORM normalize feature vectors for dataset
%
%  [SCALED, FACTOR, OFFSET] = SCALE_NORM(DATA) normalizes each column of DATA
%  to mean 0 and std 1. SCALED contains the normalized dataset, FACTOR the
%  factor to which each column has been multiplied, and OFFSET the offset
%  applied to every column after scaling.
%
%  [SCALED] = SCALE_NORM(DATA, FACTOR, OFFSET) normalizes DATA by multiplying
%  every column by the respective FACTOR element and then adding every value
%  in OFFSET to the respective column.
%
%  See also SCALE_SYM, SCALE_DATA.
%

    % compute standard deviation for every column
    div = std(data,0,1);
    div(div==0)=1;

    % compute factor if not given
    if nargin == 1
        factor = 1./(div);
    end

    % scale the data
    scaled = data*diag(factor(:));

    % compute offset if not given
    if nargin == 1
        offset = -mean(scaled);
    end

    % apply offset
    scaled = scaled + repmat(offset,size(data,1),1);

end
