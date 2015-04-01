function [svm_params paramh errh] = select_model_empirical( problem, kernel, lib, theta0)

    % MISC SETTINGS
    svm_tol = 1e-6;
    gtol = 2*svm_tol;
    stop_delta = 0.01;
    method = 'bfgs';
    max_it = 100;

    kernel = get_kernel(kernel);

    target = problem.trainlabels;
    input = problem.trainset;

    time = time_init();
    time = time_tick(time, 1);

    % initial parameter vector
    if nargin > 4 && ~isempty(theta0), theta = theta0;
    elseif strfind(kernel,'rbf') theta = [0 0];
    else theta = 0;
    end

    trainfunc = @(input,target,theta) mysvm_train( ...
        lib, kernel, input, target, theta(1), theta(2:end), false, svm_tol );
    testfunc = @(model, inputs) model_csvm(model, inputs, false, true, true);
    testfunc_deriv = @(model, inputs) model_csvm_deriv(model, inputs, false, true, true);

    if strcmp(method,'bfgs')
        err_func = @(theta) error_empirical_cv(trainfunc, testfunc, testfunc_deriv, exp(theta), problem);
        [svm_params,~,paramh,errh] = opt_bfgs_simple( err_func, false, theta, 100*svm_tol, max_it )

    else

        err_func = @(theta) error_empirical_cv(trainfunc, testfunc, testfunc_deriv, exp(theta), problem);
        [svm_params,~,paramh,errh] = opt_rprop( err_func, false, theta, stop_delta, max_it )

        % svm_params = theta;
        % err = inf;
        % errh = [ err ];
        % paramh = [svm_params];

        % err_func = @(model,deriv,args,input,target) error_empirical_cv(trainfunc, model, ...
        %                                                   deriv, tf(args), problem);

        % rprop = opt_rpropplus(svm_params);
        % for i=1:100
        %     [svm_params, err] = rprop.optimize( testfunc, testfunc_deriv, svm_params, ...
        %                                         err_func, [], input, target );
        %     paramh(end+1,:) = svm_params;
        %     errh(end+1,:) = err;
        %     if ~exponential, svm_params(svm_params<=0) = 1e-5; end
        %     if strncmp(kernel, 'rbf', 3)
        %         fprintf('svm C=%8.3f g=%8.3f err=%8.3f, delta=%8.3f, %8.3f\n', ...
        %                 svm_params(1), svm_params(2), err, rprop.delta(1), rprop.delta(2))
        %     elseif strncmp(kernel, 'lin', 3)
        %         fprintf('svm C=%8.3f err=%8.3f, delta=%8.3f\n', ...
        %                 svm_params(1), err, rprop.delta(1))
        %     end
        %     if rprop.maxdelta() < stop_delta, break, end
        % end

    end

    res = problem_test(problem,lib,kernel,exp(svm_params(1)),exp(svm_params(2:end)));
    print_test_info(res);
    time = time_tick(time, 1);
end