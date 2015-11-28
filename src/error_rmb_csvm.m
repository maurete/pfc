function [err, deriv] = error_rmb_csvm( fsvmtrain, theta, Delta, logspace, ...
                                        input, target)
%ERROR_RMB_CSVM Radius margin bound-like error function for L1 SVM-RBF.
%
%  [ERR,DERIV] = ERROR_RMB_CSVM(FSVMTRAIN,THETA,DELTA,LOGSPACE,INPUT,TARGET)
%  Trains an L1 C-SVM with RBF kernel on the input data and calculates an
%  error value related to the radius of an hypersphere containing all resulting
%  support vectors. The bound has the formula
%      RMB = (R^2 + Delta/C) * (||w||^2 + 2C sum(xi_i))
%  as is presented on Chung et al., "Radius Margin Bounds for Support Vector
%  Machines with the RBF kernel" (2002).
%  FSVMTRAIN is a function handle for the SVM training function which receives
%  INPUT, TARGET and THETA as arguments and returns a model as the one returned
%  by the MYSVM_TRAIN function.
%  THETA is a row vector with SVM parameters (C, sigma) or (S, gamma).
%  DELTA is a constant whose value is normally 0.5 or 1.
%  LOGSPACE is a boolean value that should be set to true when the optimization
%  of SVM parameters is being done in a logarithmic space.
%  INPUT and TARGET are the SVM training samples and labels, respectively.
%
%  This method requires the LIBSVM library, which you can set up in your
%  environment by invoking the SETUP function.
%
%  See also MYSVM_TRAIN, SETUP, SELECT_MODEL_RMB.
%

    % Train the SVM with entire dataset
    try
        model = fsvmtrain(input, target, theta);
    catch e,
        warning('rmb: %s: %s', e.identifier, e.message)
        err = nan; deriv = nan;
        return
    end

    % Get training function handle
    kfunc = model.kfunc_;
    if isstr(model.kfunc_), kfunc = str2func(model.kfunc_); end
    K = @(x,y) kfunc(x,y,theta(2:end)); % omit C from kernel params

    C = theta(1);

    %% Radius margin bound for L1 machines (Chung et al.)
    % Radius margin RM := (R^2 + Delta/C) * (||w||^2 + 2C sum(xi_i))
    % DRM/Dtheta = D/Dtheta(R_expr)(w_expr) + (R_expr)D/Dtheta(w_expr)

    % 1. Calculate w_expr = ||w||^2 + 2*C*sum(xi_i). According to Chung et al.,
    % eqn 5.1, the following holds:
    %   ||w||^2 + 2*C*sum(xi_i) = 2*(sum(alpha) - 0.5*sum( ...
    %                                    alpha_i*alpha_j*y_i*y_j*K(xi,xj) ))
    sum_alpha = sum(model.alpha_ .* model.svclass_ );
    obj = 0.5 * ( model.alpha_' * K(model.sv_,model.sv_) * model.alpha_ ) ...
          - sum_alpha;
    wsq = 2*(obj+sum_alpha);
    cxi = -2*obj-sum_alpha;

    % Chung et al. eqn. 5.1
    % w_expr = 2 * ( sum(model.alpha_) - ...
    %                    0.5 * ( alpha_y' * K(model.sv_,model.sv_) * alpha_y ))
    % Instead we use wsq + 2*cxi as in original code provided by authors
    w_expr = wsq + 2*cxi;

    % 2. Calculate derivative of w_expr w.r.t. theta
    %   Dw_expr/Dtheta = - sum(alpha_i*alpha_j*y_i*y_j*DK(xi,xj)/Dtheta)
    % Chung et al. equations 5.2--5.4
    dw_expr_dtheta = zeros(size(theta));
    dw_expr_dtheta(1) = (2/C) * cxi; % Authors use 2*cxi (verify)
    % Wrap the following in a try block for the case where the kernel has no
    % parameters (e.g. the linear kernel)
    try
        [~,dK]=K(model.sv_, model.sv_);
        for i=2:length(theta)
            dw_expr_dtheta(i) = - model.alpha_' * dK(:,:,i-1) * model.alpha_;
        end
    end

    % 3. Calculate R_expr = R^2 + Delta.
    %    R^2 := max_beta ( beta' * (I - K(X,X)) * beta ),
    %           subject to beta(i) >= 0 and sum(beta) = 1,
    %           where K(X,X) is the kernel matrix for the whole training set
    [Rsq, beta, bidx] = opt_rsquared( K(input, input) );
    R_expr = Rsq + Delta/C;

    % 4. Calculate DR_expr/Dtheta. This is very much like the previous step,
    %    save that we already know the optimal beta:
    %    DR_expr/Dtheta = beta' * (I - DK(x,x)/Dtheta) * beta
    dR_expr_dtheta = zeros(size(theta));
    dR_expr_dtheta(1) = - Delta/(C^2); % drexpr/dC
    try
        [~,dK]=K(input(indexes,:), input(indexes,:));
        for i=2:length(theta)
            dR_expr_dtheta(i) = - (beta' * dK(:,:,i) * beta);
        end
    end

    % 5. Ready to find our bound and its derivative
    err = [ w_expr * R_expr ];
    deriv = [dR_expr_dtheta * w_expr + dw_expr_dtheta * R_expr];

    if logspace, deriv = deriv .* theta; end

    % fprintf('RMB=%f, R^2=%f, Rexp=%f, ||w||^2=%f, wexp=%f, sum(xi)=%f\n', ...
    % err, Rsq, R_expr, wsq, w_expr, cxi);

end
