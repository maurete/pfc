function [err, deriv] = error_abs(model, modelderiv, modelarg, input, target)

    if isa(modelderiv,'function_handle')
        output = model(input, modelarg);      % Ninputs x 1
        mderiv = modelderiv(input, modelarg); % Ninputs x Nargs
    else
        [output mderiv] = model(input, modelarg);
    end

    err = 0;
    deriv = zeros(size(modelarg));

    for i=1:length(input)
        if target(i) > 0
            err   = err + 1-output(i);
            deriv = deriv - mderiv(i,:);
        else
            err = err+output(i);
            deriv = deriv + mderiv(i,:);
        end
    end
end