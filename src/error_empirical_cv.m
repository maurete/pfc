function [err, deriv] = error_empirical_cv( ftrain, fcls, fclsderiv, theta, problem)

    % number of partitions
    npart = problem.npartitions;
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

    % compute empirical error
    [Ei dEi_dz] = error_empirical(z, target);

    err = sum(Ei);
    deriv = dEi_dz' * dz;

end