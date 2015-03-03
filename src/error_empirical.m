function [err, deriv] = error_empirical(modelarg, input, target)

    % if isa(modelderiv,'function_handle')
    %     output = model(input, modelarg);      % Ninputs x 1
    %     mderiv = modelderiv(input, modelarg); % Ninputs x Nargs
    % else
    %     [output mderiv] = model(input, modelarg);
    % end

    output = model_sigmoid(input, modelarg);
    
    % empirical error E_i
    err = output;
    err(target>0) = 1-output(target>0);
    
    % dE_i/dinput_i = A * y_i * p_i * (i - p_i)
    deriv = zeros(size(err));
    deriv = modelarg(1) .* target .* output .* (1 - output);
    
end