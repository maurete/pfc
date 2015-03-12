function [svm_params, paramh, errh] = select_model_rmb ( ...
    problem, kernel, lib, theta0, randseed, gtol, max_iter, Delta )

    com = common;
    kernel = com.get_kernel(kernel);
    svm_tol = 1e-6;

    if nargin < 8 || isempty(Delta),    Delta    = 1; end
    if nargin < 7 || isempty(max_iter), max_iter = 100; end
    if nargin < 6 || isempty(gtol),     gtol     = 1e-3; end
    if nargin < 5 || isempty(randseed), randseed = 1135; end

    % initial parameter vector
    if nargin > 3 && ~isempty(theta0), theta = theta0;
    elseif com.get_kernel(kernel,'rbf',false), theta = [0 0];
    else theta = 0;
    end

    trainfunc = @(input,target,theta) mysvm_train( ...
        lib, kernel, input, target, theta(1), theta(2:end), false, svm_tol );

    rmb_func = @(theta) error_rmb_csvm( ...
        trainfunc, exp(theta), Delta, true, problem.trainset, problem.trainlabels );

    [svm_params,~,paramh,errh] = opt_bfgs_simple( rmb_func, false, theta, gtol, max_iter );

    %%% test best-performing parameters %%%

    res = com.test_csvm(problem,kernel,lib,exp(svm_params(1)),exp(svm_params(2:end)),svm_tol);
    com.print_test_info(res);

end
