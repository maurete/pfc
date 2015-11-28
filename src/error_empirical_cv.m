function [err, deriv, cvstat] = error_empirical_cv( ...
    ftrain, fcls, fclsderiv, theta, problem, feats)
%ERROR_EMPIRICAL_CV Find empirical risk via cross-validation.
%
%  [ERR,DER] = ERROR_EMPIRICAL_CV(FTRAIN,FCLS,FCLSDERIV,THETA,PROBLEM,FEATS)
%  First performs cross-validation on PROBLEM and then calculates empirical
%  risk with the ERROR_EMPIRICAL function. FTRAIN, FCLS, FCLSDERIV, PROBLEM
%  and FEATS are the same as in the CROSS_VALIDATION function. THETA is a row
%  vector with arguments to the training function as the ARGS argument of
%  CROSS_VALIDATION.
%
%  See also CROSS_VALIDATION, ERROR_EMPIRICAL.

    % Do cross-validation
    [z, target, dz, ~, cvstat] = cross_validation( ...
        problem, feats, ftrain, theta, fcls, fclsderiv);

    % Verify that outputs are indeed real-valued
    if length(unique(z)) < 4
        warning('Binary SVM outputs: expect results to be invalid.')
    end

    % Warn in case of all-zero derivatives
    if nargout > 1 && all(dz(:,1)==0)
        warning('SVM output deriv w.r.t. C is zero for all inputs.')
        dz(:,1) = 1;
    end

    % This might be an statistical atrocity due to mixing separately-trained-
    % classifier outputs in the same vector. Though, it works in practice, and
    % is simpler to calculate. Further, the classifier method is the same and
    % with the same arguments, and inputs are expected to be pretty similar
    % between partitions.
    [Ei dEi_dz] = error_empirical(z, target);

    err = sum(Ei);
    deriv = (dEi_dz' * dz) .* theta;

end
