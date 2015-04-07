function [err, deriv] = error_empirical(input, target)

    % Use 'direct' sigmoidal fitting method by default, as in
    % Keerthi, Sindhwani & Chapelle in 'An efficient Method
    % for Gradient-Based Adaptation of Hyperparameters in SVM
    % Models'. This provides greater stability to the algorithm
    t = 10;
    rho = std(input);
    A = -(t/rho);
    B = 0;
    params = [A B];

    % Try training the sigmoid on validation data
    try, params = model_sigmoid_train(input, target, 200, 1e-6, true); end

    % get posterior probabilities
    output = model_sigmoid(input, params);

    % empirical error E_i
    err = output;
    err(target>0) = 1-output(target>0);

    % dE_i/dinput_i = A * y_i * p_i * (i - p_i)
    deriv = params(1) .* target .* output .* (1 - output);

end
