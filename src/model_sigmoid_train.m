function sigmoid_params = model_sigmoid_train(output,target,max_iter,tol,fail)
%MODEL_SIGMOID_TRAIN find sigmoid parameters for SVM outputs and targets
%
%  PARAMETERS = MODEL_SIGMOID_TRAIN(SVMOUT,TARGETS,MAX_ITER,TOL,FAIL)
%  Finds best parameters for fitting a sigmoid after real-valued SVM outputs
%  in SVMOUT and TARGETS. MAX_ITER sets the maximum number of iterations, TOL
%  the maximum difference between iterations for considering convergence, and
%  FAIL is a flag indicating wether or not to raise an exception if no
%  convergence is achieved. PARAMETERS contains the best fitting parameters
%  [A,B].
%
%  This method is a Matlab reimplementation of the method found in Glasmachers
%  and Igel, "Maximum Likelihood Model Selection for 1-Norm Soft Margin SVMs
%  with Multiple Parameters" (YYYY) supplementary data, which is itself taken
%  from Platt, "Probabilistic Outputs for Support Vector Machines and
%  Comparisons to Regularized Likelihood Methods" (1999).
%
%  See also MODEL_SIGMOID, MODEL_CSVM.
%

    if nargin < 5,     fail = false; end % raise error if no convergence
    if nargin < 4,      tol = 1e-10; end %
    if nargin < 3, max_iter = 200;   end

    % initial parameters
    sigmoid_params = [0, (sum(target<0)+1)/(sum(target>0)+1)];
    % optimizer class
    rprop = opt_irpropplus(sigmoid_params);
    errhist = [];

    % loop until convergence
    for i=1:max_iter
        [sigmoid_params, err] = rprop.optimize( ...
            @model_sigmoid,[], sigmoid_params, @error_nll,[], output, target);
        % fix if A goes out of range
        if sigmoid_params(1) > 0, sigmoid_params(1) = 0; end

        % return condition
        if length(errhist) > 5 && norm(errhist(end-5:end)-err,inf) < tol
            return
        end
        errhist  = [errhist err];
    end

    % raise exception or warning if no convergence is reached
    if fail
        error('Maximum number of iterations reached without convergence.')
    end
    warning('Maximum number of iterations reached without convergence.')

end
