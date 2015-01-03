function [major minor] = stpart(seed, numel, n_part, ratio)

%% stpart - partition dataset
%
% Generate partition indexes for cross-validation.
% If ratio is not specified and there are more elements than
% partitions, every sample is used exactly once for testing.
% If a ratio is specified and is greater than 1/n_part
% the samples used for testing will be repeated.
% For leave-one-out validation the number of partition
% should be equal to the number of samples and ratio should
% be set to a number smaller than or equal to 1/n_part.
% Every sample is used for training and testing the same
% number of times when numel is a multiple of n_part and ratio
% is a multiple of 1/n_part.
%
% @param n_part:number of partitions to generate
%
% @param numel: number of elements to partition
%
% @param seed:  random seed for shuffling data
%
% @param ratio: proportion of test (validation) elements respectiv
%               to the total number of elements, e.g. if numel=400
%               and ratio=0.1 every test partition will have 40
%               elements. Default (and minimum) value = 1/n_part.
%
% @output: two matrices where each column is a partition
%          for major (train) and minor (test) respectively


    % set ratio to at least 1/npart (all elements should be tested)
    if nargin < 4, ratio = 1/n_part; end
    if ratio < 1/n_part, ratio = 1/n_part; end

    % if numel is the actual data, let it count the rows instead
    if size(numel,1) > 1, numel = size(numel,1); end

    % nmin is the actual number of test entries: numel * ratio
    nmin = max(round(numel*ratio),1);

    % step for shifting data in each successive partition
    step = numel/n_part;

    % randomly sample/shuffle source data row
    idx = strandsample(seed,numel,numel);

    % fill output matrices with zero
    major = zeros(numel-nmin,n_part);
    minor = zeros(nmin,n_part);

    % aux vectors for counting how many times each sample is used
    % for training and testing
    %tr_times = zeros(numel,1);
    %ts_times = zeros(numel,1);

    % for every partition
    for i=0:n_part-1
        % shift the whole shuffled data by (step) element
        idx2 = circshift(idx,floor(i*step));
        % save indexes into major (train) and minor(test) vector
        major(:,i+1) = idx2(nmin+1:end);
        minor(:,i+1) = idx2(1:nmin);
        %tr_times(major(:,i+1)) = tr_times(major(:,i+1)) + 1;
        %ts_times(minor(:,i+1)) = ts_times(minor(:,i+1)) + 1;
    end
end
