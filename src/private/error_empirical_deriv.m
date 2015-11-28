function [deriv, err] = error_empirical_deriv(input, target)
    [err,deriv] = error_empirical(input, target);
end