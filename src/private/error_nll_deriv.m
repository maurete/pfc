function [deriv, err] = error_nll_deriv(model,modelderiv,modelarg,input,target)
%ERROR_NLL_DERIV Derivative of the error_nll function.
%
%  [ERR,DERIV] = ERROR_NLL_DERIV(MODEL, MODELDERIV, MODELARGS, INPUTS, TARGETS)
%  has the same input arguments as in ERROR_NLL. Output arguments are also the
%  same, in reverse order.
%
%  See also ERROR_NLL.

    [err, deriv] = error_nll( model, modelderiv, modelarg, input, target);

end
