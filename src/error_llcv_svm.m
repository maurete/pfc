function [err, deriv] = error_llcv_svm( fsvmtrain, fsvmcls, fsvmderiv, theta, part, input, target)

    % number of partitions
    npart = size(part.train, 2);

    % number of svm args
    nargs = length(theta);

    % in z(i) we save SVM output for ith input vector
    z = zeros(size(target));
    dz_dtheta = zeros(length(target), nargs);

    % train svm and predict validation data
    for p=1:npart
        trainset = input( part.train(:,p), : );
        trainlbl = target( part.train(:,p) );
        svmmodel = fsvmtrain( trainset, trainlbl, theta);

        % if all(svmmodel.bsv_),
        %     warning('SVM model has no free vectors.')
        % end
        % if all(~svmmodel.bsv_),
        %     warning('SVM model has no bounded vectors.')
        % end

        validx = part.validation(:,p);
        % horrible fix for elements that escaped partitioning
        if p==npart, validx = unique( [validx; find(z==0)], 'stable' ); end

        validationset = input( validx, :);
        if isa(fsvmderiv, 'function_handle')
            z(validx) = fsvmcls(svmmodel, validationset);
            dz_dtheta(validx,:) = fsvmderiv(svmmodel, validationset);
        else, [z(validx), dz_dtheta(validx,:)] = fsvmcls(svmmodel, validationset);
        end
    end

    if all(dz_dtheta(:,1)==0),
        warning('SVM output deriv w.r.t. C is zero for all inputs.')
    end

    % also horrible: scale output decision values
    % z = z./((max(z)-min(z))/2);

    % train sigmoid on validation data
    sigmoid_params = model_sigmoid_train(z, target);

    % % train sigmoid on validation data
    % sigmoid_params = [0 (sum(target<0)+1)/(sum(target>0)+1)];
    % rprop = opt_irpropplus(sigmoid_params);
    % err = nan;
    % %fprintf('optimize sigmoid...\n')
    % for i=1:200
    %     [sigmoid_params, err] = rprop.optimize( @model_sigmoid, [], sigmoid_params, ...
    %                                             @error_nll, [], z, target );
    %     if sigmoid_params(1) > 0, sigmoid_params(1) = 0; end
    %     %fprintf('A=%8.3f B=%8.3f err=%8.3f\n', sigmoid_params(1), sigmoid_params(2), err)
    % end

    err = error_nll( @model_sigmoid, [], sigmoid_params, z, target);
    %fprintf('A=%8.3f B=%8.3f err=%8.3f\n', sigmoid_params(1), sigmoid_params(2), err)
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