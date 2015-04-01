function [deriv, output] = model_csvm_deriv(svmstruct, input, decision_values, log_C, log_kargs)
    if nargin < 5,       log_kargs = false; end
    if nargin < 4,           log_C = false; end
    if nargin < 3, decision_values = false; end
    [output, deriv] = model_csvm(svmstruct, input, decision_values, log_C, log_kargs);
end