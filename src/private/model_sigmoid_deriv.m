function [deriv, output] = model_sigmoid_deriv(input, args)
%MODEL_SIGMOID_DERIV Compute sigmoid derivatives for given input and parameters
%
%  [DERIV,OUTPUT] = MODEL_SIGMOID_DERIV(INPUT,PARAMETERS) Computes the OUTPUT
%  of the sigmoid function p=1/(1+exp(Af+B)) and its derivatives w.r.t.
%  parameters A and B. INPUT is a column vector of real-valued SVM decision
%  outputs, and PARAMETERS contains the values for A and B. DERIV is a two-
%  column matrix with derivatives w.r.t. A and B, respectively.
%
%  The sigmoid function is taken from Platt, "Probabilistic Outputs for Support
%  Vector Machines and Comparisons to Regularized Likelihood Methods" (1999)
%  and is used for obtaining probabilistic outputs for an SVM classifier.
%  The parameters A and B for a particular dataset can be computed with the
%  MODEL_SIGMOID_TRAIN function.
%
%  See also MODEL_SIGMOID, MODEL_SIGMOID_TRAIN, MODEL_CSVM.

    [output, deriv] = model_sigmoid(input, args);

end
