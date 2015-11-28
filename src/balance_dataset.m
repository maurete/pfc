function [input,labels] = balance_dataset(input,labels,randseed)
%BALANCE_DATASET balance dataset by oversampling the minority class
%
%  [OUT,OUTLABELS] = BALANCE_DATASET(DATA,LABELS,RANDSEED) oversamples the
%  minority class in DATA picking elements by RANDSEED. If data is aleady
%  class-balanced then this function returns the same inputs provided.
%

    if nargin < 3 || isempty(randseed), randseed = 1135; end

    N = numel(labels);
    npos = sum(labels>0);
    nneg = sum(labels<0);

    % if data is approximately balanced, do nothing
    if abs(npos/N-0.5) < 0.1, return; end

    % oversample positive or negative datasets
    posxtra = stpick(randseed,find(labels>0),nneg-npos);
    negxtra = stpick(randseed,find(labels<0),npos-nneg);

    allidx = stshuffle(randseed,[find(labels);posxtra;negxtra]);

    input = input(allidx,:);
    labels = labels(allidx);

end
