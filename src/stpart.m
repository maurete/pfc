function [major minor] = stpart(seed, numel, n_part, ratio, logical)

%% stpart - partition dataset
%
% Generate partition indexes for cross-validation.
% If ratio is not specified and there are more elements than
% partitions, every sample is used exactly once for testing.
% If a ratio is specified and is greater than 1/n_part
% the samples used for testing will be repeated.
% For leave-one-out validation the number of partitions
% should be equal to the number of samples and ratio should
% be set to 1/n_part or be left empty.
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

    if nargin < 5, logical = true; end

    % if numel is the actual data, let it count the rows instead
    if size(numel,1) > 1, numel = size(numel,1); end

    % randomly sample/shuffle source data row
    idx = strandsample(seed,numel,numel);

    % validate n_part argument, else set default
    if nargin > 2 && ~isempty(n_part)
        assert(isreal(n_part) && n_part > 0);
    else n_part = 5;
    end
    % validate ratio argument, else set default
    if nargin > 3 && ~isempty(ratio)
        assert(isreal(ratio) && ratio >= 0 && ratio <= 1);
    else if n_part==1, ratio=0; else ratio=1/n_part; end
    end

    % nmaj is the number of train entries: numel * (1-ratio)
    nmaj = round(numel*(1-ratio));

    % step for shifting data in each successive partition
    step = numel/n_part;

    % fill output matrices with zero
    if logical
        major = false(numel,n_part);
        minor = false(numel,n_part);
    else
        major = zeros(nmaj,n_part);
        minor = zeros(numel-nmaj,n_part);
    end

    % for every partition
    for i=0:n_part-1
        % shift the whole shuffled data by (step) element
        idx2 = circshift(idx,round(i*step));
        % save indexes into major (train) and minor(test) vector
        if logical
            major(idx2(1:nmaj),i+1) = 1;
            minor(idx2(nmaj+1:end),i+1) = 1;
        else
            major(:,i+1) = idx2(1:nmaj);
            minor(:,i+1) = idx2(nmaj+1:end);
        end
    end
    % if logical && abs(ratio-1/n_part)<1e-5
    %     ri = find(~any(minor,2))
    %     ci = find(~any(major(ri,:),1))
    %     minor(ri,ci) = 1;
    % end
end