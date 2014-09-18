function [major minor] = stpart(seed, numel, n_part, ratio)

%% StPartset - partition dataset, maybe with overlapping minor samples

% output: two matrices where each column is a partition
%    for major (train) and minor (test) respectively
%    the number of output columns is the maximum number of partitions
%    that can be generated without repeating the minor samples

    if nargin < 4, ratio = 1/n_part; end
    if size(numel,1) > 1, numel = size(numel,1); end
    
    nmin = max(round(numel*ratio),1);
    %    nmaj = numel - nmin;
    step = numel/n_part;

    % statically random sampled indexes
    idx = strandsample(seed,numel,numel);

    major = zeros(numel-nmin,n_part);
    minor = zeros(nmin,n_part);

    for i=0:n_part-1
        idx2 = circshift(idx,floor(i*step));
        major(:,i+1) = idx2(nmin+1:end);
        minor(:,i+1) = idx2(1:nmin);
        % stepi = floor(i*step);
        % major(:,i+1) = idx(mod([floor((stepi+nmin)/numel)*(mod(stepi+nmin,numel)+1):stepi, ...
        %                     stepi+nmin+1:numel-1],numel)+1);
        % minor(:,i+1) = idx(mod([stepi+1:stepi+nmin], numel)+1);
    end
    
end