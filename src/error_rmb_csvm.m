function [err, deriv] = error_rmb_csvm( fsvmtrain, theta, Delta, logspace, input, target)

    % select and train whole training data
    model = fsvmtrain(input, target, theta);
    K = @(x,y) model.kfunc_(x,y,theta(2:end)); % omit C from kernel params

    C = theta(1);

    %% Radius margin bound for L1 machines (Chung et al.)
    % Radius margin RM := (R^2 + Delta/C) * (||w||^2 + 2C sum(xi_i))
    % DRM/Dtheta = D/Dtheta(R_expr)(w_expr) + (R_expr)D/Dtheta(w_expr)

    % 1. Calculate w_expr = ||w||^2 + 2*C*sum(xi_i)
    %    - According to Chung et al. eqn 5.1, the following holds:
    %      ||w||^2 + 2*C*sum(xi_i) = 2*(sum(alpha) - 0.5*sum( alpha_i*alpha_j*y_i*y_j*K(xi,xj) ))
    sum_alpha = sum(model.alpha_ .* model.svclass_ );
    obj = 0.5 * ( model.alpha_' * K(model.sv_,model.sv_) * model.alpha_ ) - sum_alpha;
    wsq = 2*(obj+sum_alpha);
    cxi = -2*obj-sum_alpha;

    % Chung et al. eqn. 5.1
    % w_expr = 2 * ( sum(model.alpha_) - ...
    %                    0.5 * ( alpha_y' * K(model.sv_,model.sv_) * alpha_y ))
    % Instead we use wsq + 2*cxi as in original code
    w_expr = wsq + 2*cxi;

    % 2. Calculate derivative of w_expr wrt theta
    %    Dw_expr/Dtheta = - sum(alpha_i*alpha_j*y_i*y_j*DK(xi,xj)/Dtheta)
    % chung eqn 5.2--5.4
    dw_expr_dtheta = zeros(size(theta));
    dw_expr_dtheta(1) = (2/C) * cxi; % in paper 2*cxi, VERIFY
    try % try in case kernel has no parameters (e.g. linear)
        [~,dK]=K(model.sv_, model.sv_);
        for i=2:length(theta)
            dw_expr_dtheta(i) = - model.alpha_' * dK(:,:,i-1) * model.alpha_;
        end
    end

    % 3. Calculate R_expr = R^2 + Delta. This is where the struggle is!
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
    try % try in case kernel has no parameters (e.g. linear)
        [~,dK]=K(input(indexes,:), input(indexes,:));
        for i=2:length(theta)
            dR_expr_dtheta(i) = - (beta' * dK(:,:,i) * beta);
        end
    end

    % 5. Ready to find our radius margin and its derivative
    err = [ w_expr * R_expr ];
    deriv = [dR_expr_dtheta * w_expr + dw_expr_dtheta * R_expr];

    if logspace, deriv = deriv .* theta; end

    %fprintf('RMB=%f, R^2=%f, Rexp=%f, ||w||^2=%f, wexp=%f, sum(xi)=%f\n', err, Rsq, R_expr, wsq, w_expr, cxi);

end
