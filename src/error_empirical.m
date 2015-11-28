function [err, deriv] = error_empirical(clsout, target)
%ERROR_EMPIRICAL Finds empirical risk for classifier outputs
%
%  [ERR, DERIV] = ERROR_EMPIRICAL(CLSOUT, TARGET) Finds the empirical risk
%  and its derivative w.r.t. each real-valued SVM classifier output
%  given in CLSOUT. The expected risk is obtained by first fitting a sigmoid
%  to classifier outputs, then obtaining probabilistic outputs P by applying
%  the (parametrized) sigmoid function to classifier outputs. Finally, the
%  expected risk is simply 1-P when the target is 1, and P when the target
%  is 0. Note that targets can also be given in (+1,-1) values.
%  This method is presented in Ayat et al., "Automatic model selection for the
%  optimization of SVM kernels" (2005)
%
%  See also ERROR_EMPIRICAL_CV

    % Use 'direct' sigmoidal fitting method by default, as in
    % Keerthi, Sindhwani & Chapelle in 'An efficient Method
    % for Gradient-Based Adaptation of Hyperparameters in SVM
    % Models'. This provides greater stability to the algorithm
    t = 10;
    rho = std(clsout);
    A = -(t/rho);
    B = 0;
    params = [A B];

    % Try training the sigmoid on validation data
    try, params = model_sigmoid_train(clsout, target, 200, 1e-6, true); end

    % Get posterior probabilities
    output = model_sigmoid(clsout, params);

    % Empirical error (expected risk) E_i
    err = output;
    err(target>0) = 1-output(target>0);

    % dE_i/dclsout_i = A * y_i * p_i * (1 - p_i)
    deriv = params(1) .* target .* output .* (1 - output);

end
