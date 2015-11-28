function [major,minor] = stpart(seed, numel, n_part, ratio, logical)
%STPART generate cross-valiadtion partitions for dataset.
%
%  [MAJOR,MINOR] = STPART(RANDSEED,NUMEL,N_PART,RATIO,LOGICAL) generates
%  partition indexes for cross-validation. Each partition is represented as an
%  index column in MAJOR (train) and MINOR (validation) output arguments.
%  RANDSEED is the random seed for generating the partitions,
%  NUMEL can be either the whole training dataset or a scalar integer with the
%  number of elements in the training set,
%  N_PART the number of partitions to be generated (default=5),
%  RATIO is a number between 0 and 1 indicating the proportion of (# elements
%  in validation partition)/(# elements in train partition). If RATIO is 0,
%  no elements will be used for validation; likewise, if RATIO is 1 no elements
%  will be used for training. If RATIO is omitted or empty and NUMEL>NPART,
%  every sample is used exactly once for testing. If given RATIO is > 1/N_PART
%  the samples used for validation will be repeated. Thus, for generating a
%  leave-one-out partitioning, N_PART should be equal to NUMEL and RATIO should
%  be set to 1/N_PART or left empty. Every time that NUMEL is a multiple of
%  N_PART and ratio is a multiple of 1/N_PART, each sample will be used for
%  training and and validation the same number of times.
%  LOGICAL tells wether the generated indices should be returned as a logical
%  matrix (when true) or as integer indices (when false).
%

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
        idx2 = circshift(idx,[0,round(i*step)]);
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
