function [svm_params,out] = select_model_trivial(problem, feats, kernel, lib, svm_tol)

    if nargin < 5 || isempty(svm_tol), svm_tol = 1e-6; end

    kernel = get_kernel(kernel);
    features = featset_index(feats);

    % initial (and final) parameter vector
    svm_params = 0;
    if get_kernel(kernel,'rbf',false)
        svm_params = [svm_params, -log(2*numel(features))];
    end

    % Generate output model
    out = struct();
    out.features = features;
    out.trainfunc = func2str(@(in,tg) mysvm_train( lib, kernel, in, tg, ...
            exp(svm_params(1)), exp(svm_params(2:end)), false, svm_tol ));
    out.trainfuncargs = struct();
    out.trainfuncargs.lib = lib;
    out.trainfuncargs.kernel = kernel;
    out.trainfuncargs.svm_params = svm_params;
    out.trainfuncargs.svm_tol = svm_tol;
    out.classfunc = 'mysvm_classify';
    out.trainedmodel = mysvm_train( lib, kernel, problem.traindata(:,features), ...
                                    problem.trainlabels, exp(svm_params(1)), ...
                                    exp(svm_params(2:end)), false, svm_tol );

end
