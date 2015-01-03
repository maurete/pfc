function [major minor] = bstpart(seed, numel, psize, ratio)

%% bstpart - generate bootstrap partition

% output: two matrices where each column is a partition
%    for major (train) and minor (test) respectively
%    the number of output columns is the maximum number of partitions
%    that can be generated without repeating the minor samples

    if nargin < 4, ratio = 0.2; end
    if size(numel,1) > 1, numel = size(numel,1); end

    nmin = max(round(psize*ratio),1);

    % statically random sampled indexes
    idx = strandsample(seed,numel,psize);

    major = zeros(psize-nmin,1);
    minor = zeros(nmin,1);

    %idx2 = circshift(idx,floor(i*step));
    major(:) = idx(nmin+1:end);
    minor(:) = idx(1:nmin);

end