function [err, deriv] = error_nll( model, modelderiv, modelarg, input, target )
%% Negative Log Likelihood error function

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
            err = err - log(output(i));
            deriv = deriv - mderiv(i,:)/output(i);
        else
            err = err - log(1-output(i));
            deriv = deriv - mderiv(i,:)/(output(i)-1);
        end
    end

end