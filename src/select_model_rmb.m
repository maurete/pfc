function [svm_params, paramh, errh] = select_model_rmb ( dataset, featset, kernel, lib, ...
                                                      theta0, max_iter, randseed, data )

    if nargin < 8 || isempty(data),     data     = false; end
    if nargin < 7 || isempty(randseed), randseed = 1135; end
    if nargin < 6 || isempty(max_iter), max_iter = 400; end

    % MISC SETTINGS
    gtol = 1e-6 * 2;
    Delta = 1;
    exponential = true;

    com = common;

    % find out if rbf kernel is selected
    % find out if which kernel is selected
    if     strncmpi(kernel,'rbf_uni',7);    kernel = 'rbf_uni';
    elseif strncmpi(kernel,'rbf_unc',7);    kernel = 'rbf_unc';
    elseif strncmpi(kernel,'linear_uni',10); kernel = 'linear_uni';
    elseif strncmpi(kernel,'linear_unc',10); kernel = 'linear_unc';
    elseif strncmpi(kernel,'lin',3);        kernel = 'linear';
    elseif strncmpi(kernel,'rbf',4);        kernel = 'rbf';
    else error('! fatal error: unknown kernel function specified.');
    end

    features = com.featindex{featset};

    %%% Load data %%%

    if ~isstruct(data)
        data = struct();
        [data.train data.test] = load_data(dataset, randseed, false);
    end
    trainset = com.stshuffle(randseed,[data.train.real; data.train.pseudo]);
    trainlbl = trainset(:,67);
    trainset = trainset(:,features);

    trainfunc = @(input,target,theta) mysvm_train(lib, kernel, input, target, ...
                                                  theta(1), theta(2:end), false, 1e-6 );

    % initial parameter vector
    if nargin > 4 && ~isempty(theta0), theta = theta0;
    elseif strfind(kernel,'rbf') theta = [0 0];
    else theta = 0;
    end

    % param history to watch for convergence
    theta_hist = theta;
    gradient_hist = [];
    err_hist = [];

    if exponential, tf = @exp; else tf = @(t) t; end

    rmb_func = @(theta) error_rmb_csvm(trainfunc, tf(theta), Delta, ...
                                       exponential, trainset, trainlbl);

    [svm_params,~,paramh,errh] = opt_bfgs_simple( rmb_func, false, theta, 1e-6, 100 )

    %%% test best-performing parameters %%%

    res = com.run_tests(data,featset,randseed,kernel,lib,tf(svm_params(1)),tf(svm_params(2:end)) );
    com.print_test_info(res);

end
