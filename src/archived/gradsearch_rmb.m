function thhist = gradsearch_rmb ( dataset, featset, kernel, lib, logC0, loggamma0, ...
                                           max_iter, randseed, tabfile, data )

    if nargin < 10, data      = false; end
    if nargin < 9,  tabfile   = 'resultsv3.tsv'; end
    if nargin < 8,  randseed  = 1135; end
    if nargin < 7,  max_iter  = 400; end
    if nargin < 6,  loggamma0 = 0; end
    if nargin < 5,  logC0     = 0; end

    % MISC SETTINGS
    gtol = 1e-6 * 2;
    Delta = 1;

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

    % fprintf('#\n> begin\t\tsvm-%s\n#\n',kernel);

    time = com.time_init();

    %%% Load data %%%

    if ~isstruct(data)
        data = struct();
        [data.train data.test] = load_data(dataset, randseed, false);
    end

    % initial parameter vector
    logtheta = [ logC0;       % log C
                 loggamma0 ]; % log gamma

    % param history to watch for convergence
    logtheta_hist = logtheta;
    loggradient_hist = [];
    err_hist = [];
    H = eye(2);

    rmfunc = @(logtheta) RM_eval(dataset, featset, kernel, lib, exp(logtheta(1)), ...
                                 exp(logtheta(2)), Delta, true, randseed, data);


    [theta RM theta_hist RM_hist] = min_bfgs_simple( rmfunc, false, logtheta, 1e-6, 100 )

    %return


    % %% BFGS Quasi-Newton method

    % th0 = [logC0; loggamma0];
    % [f0 Re dRe we dwe model dRM] = rmfunc(th0);
    % gfk = [dRe*we + dwe*Re] .* exp(th0)
    % dRM

    % Hk = H;
    % thk = th0;
    % gfk0 = gfk;
    % sk = 2*gtol;
    % pk = -Hk*gfk;

    % thhist = th0;

    % for n = 1:max_iter
    %     if norm(gfk,1) < gtol, fprintf('norm gfk < gtol'), break, end % gradient successfully reduced
    %     if (gfk'*gfk)/(gfk0'*gfk0) < 1e-6, fprintf('rel gfk/gfk0 < gtol'), break, end % gradient successfully reduced

    %     if pk.*gfk > 0
    %         warning('pk not in a descent direction')
    %         pk = -pk;
    %     end

    %     lastf = rmfunc(thk);

    %     lambdak = line_search(rmfunc, thk, pk, gfk, f0);
    %     if lambdak < 0
    %         warning('parameter out of bounds!')
    %         break
    %     end

    %     thkp1 = thk + lambdak * pk;
    %     sk    = thkp1 - thk;
    %     thk   = thkp1;

    %     thhist = [thhist thk];

    %     [fkp1 Re1 dRe1 we1 dwe1 model1 dRM1] = rmfunc(thk);
    %     gfkp1 = [dRe1*we1 + dwe1*Re1] .* thk
    %     dRM1
    %     yk = gfkp1 -gfk;

    %     if lastf-fkp1 < 1e-6
    %         warning('function decrease less than tolerance (1e-6)')
    %         break
    %     end

    %     if yk'*sk == 0
    %         error('numerical error detected!')
    %         break
    %     end

    %     rhok = 1/(yk'*sk);

    %     if rhok > 0
    %        Hk = (eye(2)-[sk*yk']*rhok)*(Hk*(eye(2)-[yk*sk']*rhok)) + sk*sk'*rhok;
    %     end

    %     gfk = gfkp1;
    %     pk = -Hk*gfk;

    %     f0 = fkp1;


    %     % % 0. Gradient in (ln(C), ln(gamma)) space
    %     % % grad_logspace = [[ dRe .* theta ] * we + ...
    %     % %                  [ dwe .* theta ] * Re ];

    %     % %loggrad = [dRe.*exp(logtheta)] * we + [dwe.*exp(logtheta)] * Re;
    %     % loggrad = [dRe.*exp(logtheta)] * we + [dwe.*exp(logtheta)] * Re;
    %     % loggradient_hist = [loggradient_hist loggrad];


    %     % step = 1;
    %     % while norm(step*loggrad) > 1
    %     %     step = step / 2;
    %     % end

    %     % Ptheta = @(logtheta) max([[-10;-10],min([[10;10],logtheta],[],2)],[],2);
    %     % logtheta = Ptheta(logtheta + step*loggrad);

    %     % logtheta_hist = [logtheta_hist logtheta ];

    %     fprintf('Step %d logC %f loggamma %f loggrad (%f, %f) RM %f\n', n, thk(1), thk(2), ...
    %     gfk(1), gfk(2), f0)

    %     % if norm(loggradient_hist(:,end))/norm( loggradient_hist(:,1) ) < 1e-3 || norm(loggrad) < 1e-3
    %     %     fprintf('Convergence! best log2C = %7.4f, log2gamma = %7.4f\n', ...
    %     %             log2(exp(logtheta(1))), log2(exp(logtheta(2))))
    %     %     break
    %     % end

    % end

        % err_hist = [ err_hist RM];
        % delta = 0.0001 * (it/10); %exp( -norm(mean_gradient,2)/10 )
        % theta = theta + dRM_dtheta * delta;
        % theta_hist = [theta_hist theta];

        %log2theta_hist = log2(exp(logtheta_hist));


    res = com.run_tests(data,featset,randseed,kernel,lib,exp(theta(1)),exp(theta(2)) );
    com.print_test_info(res);


    %sigma = (2*Result.Best_Gamma)^(-1/2);

    %Result

    %log2(sigma)


    %%% test best-performing parameters %%%

    % fprintf('#\n+ test\n+ boxconstraint\t%4.2f\n+ rbf_sigma\t%4.2f\n',...
    %          log2(Result.Best_C), log2(sigma) )


    % com.write_test_info_ext(tabfile, dataset, featset, ['svm-rbf'], ...
    %                         log2(Result.Best_C), log2(sigma), res, randseed, 0);

    % com.print_test_info(res);
    %com.time_tick(time,0);
end
