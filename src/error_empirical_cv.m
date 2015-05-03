function [err, deriv, cvstat] = error_empirical_cv( ftrain, fcls, fclsderiv, theta, problem, feats)

    % perform cross validation
    [z,target,dz,~,cvstat] = cross_validation(problem, feats, ftrain, theta, fcls, fclsderiv);

    if length(unique(z)) < 4,
        warning('Binary SVM outputs: expect results to be invalid.')
    end
    if nargout > 1 && all(dz(:,1)==0)
        warning('SVM output deriv w.r.t. C is zero for all inputs.')
        dz(:,1) = 1;
    end

    % compute empirical error
    [Ei dEi_dz] = error_empirical(z, target);

    err = sum(Ei);
    deriv = (dEi_dz' * dz) .* theta;

end
