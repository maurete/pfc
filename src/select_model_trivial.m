function [svm_params,res] = select_model_trivial(problem, feats, kernel, lib)

    kernel = get_kernel(kernel);
    features = featset_index(feats);

    % initial (and final) parameter vector
    svm_params = 0;
    if get_kernel(kernel,'rbf',false)
        svm_params = [svm_params, log(sqrt(0.5/numel(features)))];
    end

    res = problem_test(problem,feats,lib,kernel,exp(svm_params(1)),exp(svm_params(2:end)));
    print_test_info(res);

end
