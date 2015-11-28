function [deriv, err] = error_nll_deriv( model, modelderiv, modelarg, input, target )
    [err, deriv] = error_nll( model, modelderiv, modelarg, input, target);
end