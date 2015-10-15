function [RM dRM model] = RM_eval(dataset, featset, kernel, lib, C, gamma, Delta, log, randseed, data)

    if nargin < 10, data = false; end
    if nargin < 9, randseed = 1135; end
    if nargin < 8, log = false; end
    if nargin < 7, Delta = 1; end

    com = common;

    % find out if rbf kernel is selected
    % find out if which kernel is selected
    if     strncmpi(kernel,'rbf_uni',7);    kernel = 'rbf_uni';
    elseif strncmpi(kernel,'linear_uni',7); kernel = 'linear_uni'; return;
    elseif strncmpi(kernel,'lin',3);        kernel = 'linear'; return;
    elseif strncmpi(kernel,'rbf',4);        kernel = 'rbf';
    else error('! fatal error: unknown kernel function specified.');
    end

    features = com.featindex{featset};

    %%% Load data %%%

    if ~isstruct(data)
        data = struct();
        [data.train data.test] = load_data(dataset, randseed, false);
    end

    % select whole training data
    trainset = com.shuffle([ data.train.real; ...
                        data.train.pseudo ] );

    if isempty(strfind(kernel,'uni'))
        % classical RBF or linear kernel selected
        % The 'classic' RBF kernel and its derivatives
        model = mysvm_train( lib, kernel, trainset(:,features), ...
                             trainset(:,67), C, gamma, ...
                             false, 1e-6 );
        K     = @(x,y) kernel_rbf(x,y,gamma);
        dK_dg = @(x,y) kernel_rbf_deriv(x,y,gamma);
        dK_dC = K;
    else
        % The 'unified' RBF kernel and its derivatives
        model = mysvm_train( lib, kernel, trainset(:,features), ...
                             trainset(:,67), 1e5, [C gamma], ...
                             false, 1e-6 );
        K     = @(x,y) kernel_rbf_uni(x,y,C,gamma);
        dK_dg = @(x,y) kernel_rbf_uni_dgamma(x,y,C, gamma);
        dK_dC = K;
    end

    %% Radius margin bound for L1 machines (Chung et al.)
    % Radius margin RM := (R^2 + Delta/C) * (||w||^2 + 2C sum(xi_i))
    % DRM/Dtheta = D/Dtheta(R_expr)(w_expr) + (R_expr)D/Dtheta(w_expr)

    % 1. Calculate w_expr = ||w||^2 + 2*C*sum(xi_i)
    %    - According to Chung et al. eqn 5.1, the following holds:
    %      ||w||^2 + 2*C*sum(xi_i) = 2*(sum(alpha) - 0.5*sum( alpha_i*alpha_j*y_i*y_j*K(xi,xj) ))

    % aux vector
    alpha_y = [ model.svclass_ .* model.alpha_ ];
    sum_alpha = sum(alpha_y);

    %if strcmp(model.lib_,'matlab'), alpha_y = -alpha_y; sum_alpha = -sum_alpha; end

    obj = 0.5 * ( model.alpha_' * K(model.sv_,model.sv_) * model.alpha_ ) - sum_alpha;

    wsq = 2*(obj+sum_alpha);

    cxi = -2*obj-sum_alpha;


    % Chung et al. eqn. 5.1 % VERIFY sign is correct
    % w_expr = 2 * ( sum(model.alpha_) - ...
    %                    0.5 * ( alpha_y' * K(model.sv_,model.sv_) * alpha_y ))

    w_expr = wsq + 2*cxi;

    % 2. Calculate derivative of w_expr wrt theta
    %    Dw_expr/Dtheta = - sum(alpha_i*alpha_j*y_i*y_j*DK(xi,xj)/Dtheta)

    % chung eqn 5.2--5.4
    dw_expr_dtheta = [ (2/C) * cxi; ... %dwexpr/dC
                       - alpha_y' * dK_dg(model.sv_,model.sv_) * alpha_y ]; %dwexpr/dgamma

    % 3. Calculate R_expr = R^2 + Delta. This is where the struggle is!
    %    R^2 := max_beta ( beta' * (I - K(X,X)) * beta ),
    %           subject to beta(i) >= 0 and sum(beta) = 1,
    %           where K(X,X) is the kernel matrix for the whole training set

    %[Rsq, beta, indexes] = Rsquared( K(trainset(:,features), trainset(:,features)) );
    %[Rsq, beta, indexes] = Rsquared2( K(trainset(:,features), trainset(:,features)) );
    %sum(beta)
    [Rsq, beta, indexes] = Rsquared2( K(trainset(:,features), trainset(:,features)) );
    sum(beta);
    % Delta should be a positive number (close to 1?). We set it to 1.
    %Delta = 1; % 1 in Chung libsvm code
    R_expr = Rsq + Delta/C;

    % 4. Calculate DR_expr/Dtheta. This is very much like the previous step,
    %    save that we already know the optimal beta:
    %    DR_expr/Dtheta = beta' * (I - DK(x,x)/Dtheta) * beta

    dR_expr_dtheta = [ - Delta/(C^2) ; % drexpr/dC
                       - (beta' * dK_dg(trainset(indexes,features),trainset(indexes,features)) * beta) ] ;


    % 5. Ready to find our radius margin and its derivative

    RM = [ w_expr * R_expr ] ;
    dRM_dtheta = [dR_expr_dtheta * w_expr + dw_expr_dtheta * R_expr];

    Re = R_expr;
    dRe = dR_expr_dtheta;
    we = w_expr;
    dwe = dw_expr_dtheta;

    %fprintf('RMB=%f, R^2=%f, Rexp=%f, ||w||^2=%f, wexp=%f, sum(xi)=%f\n', RM, Rsq, R_expr, wsq, w_expr, cxi);

    dRM = [dRe*we + dwe*Re];
    if log, dRM = dRM .* [C; gamma]; end

end
