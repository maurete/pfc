function [major minor] = stpart(seed, dataset, n_part)

%% StPartset - partition dataset, non-overlapping minor samples

% output: two matrices where each column is a partition
%    for major (train) and minor (test) respectively
%    the number of output columns is the maximum number of partitions
%    that can be generated without repeating the minor samples

    mult = floor(size(dataset,1)/n_part);
    len  = mult*n_part;

    % statically random sampled indexes
    idx = strandsample(seed,size(dataset,1),len);

    major = zeros(len-mult,n_part);
    minor = zeros(mult,n_part);

    for i=0:n_part-1
        major(:,i+1) = idx([1:i*mult (i+1)*mult+1:len]);
        minor(:,i+1) = idx([i*mult+1:(i+1)*mult]);
    end
    
end