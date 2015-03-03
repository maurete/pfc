function [major minor] = partset (dataset, n_maj, limit)

%% Partset - partition dataset, non-overlapping minor samples

% output: two matrices where each column is a partition
%    for major (train) and minor (test) respectively
%    the number of output columns is the maximum number of partitions
%    that can be generated without repeating the minor samples

    len = size(dataset,1);
    if nargin > 2
        len = limit;
    end
    
    % randomly sampled indexes
    idx = randsample(size(dataset,1),len);
    size(idx);

    major = [];
    minor = [];
    n_min = len-n_maj;

    i = 0;
    while(i+n_min<len)
        major = [major idx([1:i i+n_min+1:len])];
        minor = [minor idx([i+1:i+n_min])];
        i = i+n_min;
    end
end