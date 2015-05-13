function [svm_params, out, paramh, errh, ntrain] = select_model_rmb ( ...
    problem, feats, kernel, lib, theta0, gtol, max_iter, Delta )

    features = featset_index(feats);
    kernel = get_kernel(kernel);
    svm_tol = 1e-6;

    if nargin < 8 || isempty(Delta),    Delta    = 1; end
    if nargin < 7 || isempty(max_iter), max_iter = 100; end
    if nargin < 6 || isempty(gtol),     gtol     = 1e-3; end

    % initial parameter vector
    if nargin > 4 && ~isempty(theta0), theta = theta0;
    elseif get_kernel(kernel,'rbf',false), theta = [0 0];
    else theta = 0;
    end

    time = time_init();
    time = time_tick(time, 1);

    trainfunc = @(input,target,theta) mysvm_train( ...
        lib, kernel, input, target, theta(1), theta(2:end), false, svm_tol );

    rmb_func = @(theta) error_rmb_csvm( ...
        trainfunc, exp(theta), Delta, true, problem.traindata(:,features), problem.trainlabels );

    [svm_params,~,paramh,errh,ntrain] = opt_bfgs_simple( rmb_func, false, theta, gtol, max_iter );


    % Generate output model
    out = struct();
    out.features = features;
    out.trainfunc = @(in,tg) mysvm_train( lib, kernel, in, tg, ...
            exp(svm_params(1)), exp(svm_params(2:end)), false, svm_tol );
    out.classfunc = @mysvm_classify;
    out.trainedmodel = mysvm_train( lib, kernel, problem.traindata(:,features), ...
                                    problem.trainlabels, exp(svm_params(1)), ...
                                    exp(svm_params(2:end)), false, svm_tol );

    time = time_tick(time, 1);

end
