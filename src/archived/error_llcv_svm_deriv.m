function [deriv, err] = error_llcv_svm_deriv( fsvmtrain, fsvmcls, fsvmderiv, theta, part, input, target)
    [err, deriv] = error_llcv_svm( fsvmtrain, fsvmcls, fsvmderiv, theta, part, input, target);
end