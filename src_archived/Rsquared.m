function [obj, beta, idx, iterations, fevalcount] = Rsquared( K, limit )
% K is the computed kernel for all training vectors

    % set to Inf to avoid kernel subsampling
    if nargin < 2, limit = 500; end

    % Downsample kernel if it's too big
    % DANGER this may not be appropiate
    len = size(K,1);
    idx = 1:len;
    if len > limit
        idx = randperm(len,limit);
        len = limit;
        K = K(idx,idx);
    end

    % The function to maximize * -1
    %func = @(beta) beta' * ( K - eye(len)) * beta;
    % Chung 1.3
    func = @(beta) beta' * ( K ) * beta - 1;

    % Initial guess
    beta0 = ones(len,1)/len;

    % Up the maximum func evaluations to 100000 (default: 3000)
    try
        options = optimoptions('fmincon','MaxFunEvals',100000,'Display','off');
    catch
        options = optimset('Algorithm','interior-point','MaxFunEvals',100000,'Display','off');
    end

    % Do the barrel roll!
    [beta, RR, exitflag, output] = ...
        fmincon( func, beta0, ... %function handle
                 -eye(len), zeros(len,1), ... % beta >=0
                 ones(1,len), -1, ... % sum(beta) = 1
                 [], [], [], options );

    iterations = output.iterations;
    fevalcount = output.funcCount;

    obj = -RR;
    beta = -beta;
end