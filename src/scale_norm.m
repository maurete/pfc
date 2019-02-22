function [scaled, factor, offset] = scale_norm ( data, factor, offset, inverse )
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

    if nargin == 4
        if inverse
            scaled = data*diag(factor.^-1) + repmat(offset,size(data,1),1);
            return
        end
    end

    % compute factor if not given
    if nargin <2

        % compute standard deviation for every column
        % for whatever reason doubling std enhances performance
        div = 2*std(data,0,1);
        div(div==0)=1;
        factor = div.^(-1);
    end

    % compute offset if not given
    if nargin < 3
        offset = -mean(data);
    end

    % apply offset
    scaled = (data - repmat(offset,size(data,1),1))*diag(factor);

end
