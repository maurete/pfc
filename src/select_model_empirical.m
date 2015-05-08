function [svm_params,paramh,errh,res,ntrain,out] = select_model_empirical( problem, feats, kernel, lib, theta0, max_it)

    if nargin < 5 || isempty(max_it), max_it = 100; end

    % MISC SETTINGS
    svm_tol = 1e-6;
    gtol = svm_tol/10^(log10(svm_tol)/3);
    stop_delta = svm_tol/10^(log10(svm_tol)/2);
    method = 'bfgs';

    kernel = get_kernel(kernel);

    target = problem.trainlabels;
    input = problem.traindata;

    time = time_init();
    time = time_tick(time, 1);

    % initial parameter vector
    if nargin > 4 && ~isempty(theta0), theta = theta0;
    elseif strfind(kernel,'rbf') theta = [0 0];
    else theta = 0;
    end

    trainfunc = @(input,target,theta) mysvm_train( ...
        lib, kernel, input, target, theta(1), theta(2:end), ...
        false, ... % autoscale
        svm_tol ...
        );

    testfunc = @(model, input) model_csvm( ...
        model, input, ...
        true, ... % decision values
        true, ... % c_log (for derivative)
        true ...  % kparam_log (for derivative)
        );

    testfunc_deriv = @(model, input) model_csvm_deriv( ...
        model, input, ...
        true, ... % decision values
        true, ... % c_log (for derivative)
        true ...  % kparam_log (for derivative)
        );

    if strcmp(method,'bfgs')
        err_func = @(theta) error_empirical_cv(trainfunc, testfunc, testfunc_deriv, exp(theta), problem, feats);
        [svm_params,~,paramh,errh,ntrain] = opt_bfgs_simple( err_func, false, theta, 100*svm_tol, max_it )

    else
        err_func = @(theta) error_empirical_cv(trainfunc, testfunc, testfunc_deriv, exp(theta), problem, feats);
        [svm_params,~,paramh,errh,ntrain] = opt_rprop( err_func, false, theta, stop_delta, max_it )
    end

    % Generate output model
    out = struct();
    features = featset_index(feats);
    out.features = features;
    out.trainfunc = @(in,tg) mysvm_train( lib, kernel, in, tg, ...
            exp(svm_params(1)), exp(svm_params(2:end)), svm_tol );
    out.classfunc = @mysvm_classify;
    out.trainedmodel = mysvm_train( lib, kernel, problem.traindata(:,features), ...
                                    problem.trainlabels, exp(svm_params(1)), ...
                                    exp(svm_params(2:end)), svm_tol );

    res = problem_test(problem,feats,lib,kernel,exp(svm_params(1)),exp(svm_params(2:end)));
    print_test_info(res);
    time = time_tick(time, 1);

end
