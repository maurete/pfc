function [deriv, output] = model_csvm_deriv(svmstruct, input, decision_values, exponential)
    if nargin < 4,     exponential = false; end
    if nargin < 3, decision_values = false; end
    [output, deriv] = model_csvm(svmstruct, input, decision_values, exponential);
end