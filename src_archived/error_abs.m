function [err, deriv] = error_abs( model, modelderiv, modelarg, input, target )
%% Absolute error function

    if isa(modelderiv,'function_handle')
        output = model(input, modelarg);      % Ninputs x 1
        mderiv = modelderiv(input, modelarg); % Ninputs x Nargs
    else
        [output mderiv] = model(input, modelarg);
    end

    err = 0;
    deriv = zeros(size(modelarg));

    for i=1:length(input)
        err = err + abs(target(i)-output(i));
        deriv = deriv - (mderiv(i,:).*sign(target(i)-output(i)));
    end
end
