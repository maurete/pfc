function [err, deriv] = error_empirical(input, target)

    % train sigmoid on validation data
    sigmoid_params = model_sigmoid_train(input, target);

    % get posterior (?) probabilities
    output = model_sigmoid(input, sigmoid_params);

    % empirical error E_i
    err = output;
    err(target>0) = 1-output(target>0);

    % dE_i/dinput_i = A * y_i * p_i * (i - p_i)
    deriv = sigmoid_params(1) .* target .* output .* (1 - output);
end