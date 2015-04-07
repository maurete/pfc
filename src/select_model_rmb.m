function [svm_params, paramh, errh,res] = select_model_rmb ( ...
    problem, kernel, lib, theta0, gtol, max_iter, Delta )

    kernel = get_kernel(kernel);
    svm_tol = 1e-6;

    if nargin < 7 || isempty(Delta),    Delta    = 1; end
    if nargin < 6 || isempty(max_iter), max_iter = 100; end
    if nargin < 5 || isempty(gtol),     gtol     = 1e-3; end

    % initial parameter vector
    if nargin > 3 && ~isempty(theta0), theta = theta0;
    elseif get_kernel(kernel,'rbf',false), theta = [0 0];
    else theta = 0;
    end

    time = time_init();
    time = time_tick(time, 1);

    trainfunc = @(input,target,theta) mysvm_train( ...
        lib, kernel, input, target, theta(1), theta(2:end), false, svm_tol );

    rmb_func = @(theta) error_rmb_csvm( ...
        trainfunc, exp(theta), Delta, true, problem.trainset, problem.trainlabels );

    [svm_params,~,paramh,errh] = opt_bfgs_simple( rmb_func, false, theta, gtol, max_iter );

    %%% test best-performing parameters %%%

    res = problem_test(problem,lib,kernel,exp(svm_params(1)),exp(svm_params(2:end)),svm_tol);
    print_test_info(res);
    time = time_tick(time, 1);

end
