function [input,labels] = balance_dataset(input,labels,randseed)

    if nargin < 3 || isempty(randseed), randseed = 1135; end

    N = numel(labels);
    npos = sum(labels>0);
    nneg = sum(labels<0);

    % if data is approximately balanced, do nothing
    if npos < 0.55*N && npos > 0.45*N, return; end

    posidx = stpick(randseed,find(labels>0),nneg);
    negidx = stpick(randseed,find(labels<0),npos);

    allidx = stshuffle(randseed,[posidx;negidx]);

    input = input(allidx,:);
    labels = labels(allidx);

end
