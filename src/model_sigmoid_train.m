function sigmoid_params = model_sigmoid_train(output, target, max_iter, tol)
    if nargin < 4,      tol = 1e-10; end
    if nargin < 3, max_iter = 200;   end
    sigmoid_params = [0 (sum(target<0)+1)/(sum(target>0)+1)];
    rprop = opt_irpropplus(sigmoid_params);
    errhist = [];
    for i=1:max_iter
        [sigmoid_params, err] = rprop.optimize( @model_sigmoid, [], sigmoid_params, ...
                                                @error_nll, [], output, target );
        if sigmoid_params(1) > 0, sigmoid_params(1) = 0; end
        if length(errhist) > 5 && norm(errhist(end-5:end)-err,inf) < tol, return, end
        errhist  = [errhist err];
    end
    warning('Maximum number of iterations reached without convergence.')
end