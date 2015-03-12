function [err, deriv] = error_llcv_svm( ftrain, fcls, fclsderiv, theta, problem)

    % number of partitions
    npart = size(part.train, 2);
    % number of classifier args
    nargs = length(theta);

    % perform cross validation
    [z,target,dz] = cross_validation(problem, ftrain, theta, fcls, fclsderiv);

    % if length(unique(z)) < 4,
    %     warning('Binary outputs, this may fail.')
    % end
    if all(dz(:,1)==0),
        warning('SVM output deriv w.r.t. C is zero for all inputs.')
    end

    % train sigmoid on validation data
    sigmoid_params = model_sigmoid_train(z, target);

    % compute nll error
    err = error_nll( @model_sigmoid, [], sigmoid_params, z, target);

    if nargout < 2, return, end

    % compute derivative
    [p dp] = model_sigmoid(z, sigmoid_params);
    deriv = zeros(1, nargs);
    for i=1:length(target)
        if target(i) > 0, dL_dp = -1/p(i);
        else dL_dp = -1/(p(i)-1);
        end
        %compute derivative of the sigmoid
        dp_dz = -sigmoid_params(1) * p(i) * (1-p(i));
        % total derivative = partial derivative
        deriv = deriv + dL_dp * dp_dz * dz_dtheta(i,:);
    end

end