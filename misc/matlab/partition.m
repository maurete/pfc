function [train test] = partition ( all, ntrain, ntest )

    if isstruct(all)
        N = length(all);
    else
        [N ignore] = size(all);
    end
    
    if nargin < 2
        ntrain = round(N*0.7);
    end
    if nargin < 3
         ntest = N - ntrain;
    end

    % N
    % ntrain
    % ntrain + ntest
    
    [ignore idx] = sort(rand(N,1));
    
    if isstruct(all)
        train = all(idx(1:ntrain));
        test  = all(idx(ntrain+1:ntrain+ntest));
    else
        train = all(idx(1:ntrain),:);
        test  = all(idx(ntrain+1:ntrain+ntest),:);
    end

end