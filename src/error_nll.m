function [err, deriv] = error_nll( model, modelderiv, modelarg, input, target )
%ERROR_NLL Negative log-likelihood error function
%
%  [ERR,DERIV] = ERROR_NLL(MODEL, MODELDERIV, MODELARGS, INPUTS, TARGETS)
%  applies the given MODEL with arguments MODELARGS to the INPUTS and
%  then finds the aggregate negative log likelihood for given TARGETS.
%  MODEL is a function handle which receives a N-by-M matrix and returns an
%  N-by-1 column vector where each element is the model output for the
%  respective row of the input matrix. MODEL must also receive the model
%  arguments as second parameter, even when the model has no parameters.
%  MODELDERIV returns the derivative of the model output w.r.t. each one of
%  the model arguments. Thus, if the model has K arguments MODELDERIV
%  must return an N-by-K matrix where each row is the derivative of the
%  respective input w.r.t. each model argument.
%  MODELARGS is a row vector containing model parameters.
%  When MODELDERIV is not supplied, the derivatives must be returned by
%  MODEL as a second output argument.
%  INPUTS is an N-by-M matrix where each row represents a sample input
%  for MODEL.
%  TARGETS is an N-long column vector where the ith element is the target
%  output value of the MODEL for the ith row of INPUT.
%
%  The negative log-likelihood function is defined for each sample as
%  nll_i = - log(output_i)    when target_i is > 0,
%  nll_i = - log(1-output_i)  otherwise.
%  The value returned by this function is the sum of all nll_i for every
%  row in INPUT.

    % if given modelderiv, calculate model outputs and derivatives separately
    if isa(modelderiv,'function_handle')
        output = model(input, modelarg);      % Ninputs x 1
        mderiv = modelderiv(input, modelarg); % Ninputs x Nargs
    else
        % else we expect the given model function to also return derivatives
        % as second output argument
        [output,mderiv] = model(input, modelarg);
    end

    err = 0;
    deriv = zeros(size(modelarg));

    % this for-loop is faster than equivalent matrix operations below
    for i=1:length(input)
        if target(i) > 0
            err = err - log(output(i));
            deriv = deriv - mderiv(i,:)/output(i);
        else
            err = err - log(1-output(i));
            deriv = deriv - mderiv(i,:)/(output(i)-1);
        end
    end

    % the same as above in matrix operations fashion, slower
    % err = sum(-log( ((target>0).*output) + (1-target>0).*(1-output) ),1);
    % deriv = sum( -diag( ((target>0)./output)+(1-target>0)./(output-1) ) ...
    %              * mderiv, 1);

end
