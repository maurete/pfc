function [err, deriv] = error_empirical_csvm( fsvmtrain, fsvmcls, fsvmderiv, theta, part, input, target)

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

    [Ei dEi_dz] = error_empirical(z, target);
    
    err = sum(Ei);
    deriv = dEi_dz' * dz_dtheta;
    
end