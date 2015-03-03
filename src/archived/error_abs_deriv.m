function [deriv, err] = error_abs_deriv(model, modelderiv, modelarg, input, target)
    [err, deriv] = error_abs(model, modelderiv, modelarg, input, target);
end