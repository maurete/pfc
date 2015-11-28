function [output, deriv] = model_sigmoid(input, args)
%MODEL_SIGMOID Compute sigmoid outputs for given input and parameters
%
%  [OUTPUT,DERIV] = MODEL_SIGMOID(INPUT,PARAMETERS) Computes the OUTPUT of the
%  sigmoid function p=1/(1+exp(Af+B)) and its derivatives w.r.t. parameters
%  A and B. INPUT is a column vector of real-valued SVM decision outputs, and
%  PARAMETERS contains the values for A and B. DERIV is a two-column matrix
%  with derivatives w.r.t. A and B, respectively.
%
%  The sigmoid function is taken from Platt, "Probabilistic Outputs for Support
%  Vector Machines and Comparisons to Regularized Likelihood Methods" (1999)
%  and is used for obtaining probabilistic outputs for an SVM classifier.
%  The parameters A and B for a particular dataset can be computed with the
%  MODEL_SIGMOID_TRAIN function.
%
%  See also MODEL_SIGMOID_TRAIN, MODEL_CSVM.

    A = args(1);
    B = args(2);
    output = zeros(size(input));
    deriv  = zeros(length(input), length(args));
    for i=1:length(input)
        e = exp(A*input(i)+B); f = 1/(1+e);
        output(i) = f;
        d = -f*f*e;
        deriv(i,:) = [ d*input(i), d ];
    end

end
