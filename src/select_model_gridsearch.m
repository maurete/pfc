function [svm_params,grid] = select_model_gridsearch ( problem, kernel, lib, iter, ...
                                                      criterion, strategy, svm_tol )

    com = common;
    gu = gridutil;
    gt = gridtune;

    if nargin < 7 || isempty(svm_tol), svm_tol = 1e-6; end
    if nargin < 6 || isempty(strategy), strategy = 'zoom'; end
    if nargin < 5 || isempty(criterion), criterion = 'gm'; end
    if nargin < 4 || isempty(iter), iter = 2; end

    % grid layer names
    gnames = { 'test'    , ... % tested flag
               'ign'     , ... % ignore flag
               'se'      , ... % sensitivity
               'sp'      , ... % specificity
               'gm'      , ... % gm
               'emp'     , ... % empirical error (Adankon et al.)
               'nll'     , ... % negative log likelihood (Glasmachers & Igel; Keerthi et al.)
               'rmb'     , ... % RMB (Chung et al.)
               'mcc'       ... % Matthews Correlation Coefficient
         };

    % grid indexes
    gi = struct();
    % linearized grid indexes
    lgi = struct();
    lgi.C = 1;
    lgi.gamma = 2;
    % auto number grid indexes
    for i=1:length(gnames)
        gi.(gnames{i}) = i;
        lgi.(gnames{i}) = i+2;
    end

    kernel = com.get_kernel(kernel);
    % initial grid parameters (from Hsu et al.)
    box0 = pow2([-15:2:15]);
    gam0 = 0;
    if com.get_kernel(kernel, 'rbf', false)
        gam0 = pow2([-15:2:3]);
    end

    % initial grid
    grid = gu.new(box0, gam0, [], gnames);

    % training, testing and error functions
    if com.get_kernel(kernel, 'uni', false)
        trainfunc = @(input,target,theta) mysvm_train( ...
            lib, kernel, input, target, 1e5, theta);
    else
        trainfunc = @(input,target,theta) mysvm_train( ...
            lib, kernel, input, target, theta(1), theta(2:end) );
    end
    testfunc = @(model, input) model_csvm(model, input,true);
    eempfunc = @(output, target) log(sum(error_empirical(output, target)));
    ermbfunc = @(input, target, theta) log(error_rmb_csvm( ...
        trainfunc, theta, 1, false, input, target));
    enllfunc = @(z,t) log(error_nll(...
        @model_sigmoid, [], model_sigmoid_train(z,t), z, t));

    % select criterion for (max|min)imisation
    crit_gi = gi.(lower(criterion));
    crit_lgi = lgi.(lower(criterion));
    crit_sgn = 1;
    if any(strcmpi(criterion, {'emp', 'nll', 'rmb'}))
        crit_sgn = -1;
    end

    time = com.time_init();
    time = com.time_tick(time, 1);

    %%% grid-search %%%

    for g = 1:iter

        %linearize grid
        lgrid = gu.pack(grid);

        % select elements to be tested
        g_idx = find(1-[lgrid(:,lgi.test)|lgrid(:,lgi.ign)]);

        fprintf('#\n> gridsearch iteration\t%g\n> parameters\t%d\n', ...
                g, numel(g_idx));

        % set error grid values to inf
        lgrid(g_idx,lgi.emp) = inf;
        lgrid(g_idx,lgi.rmb) = inf;
        lgrid(g_idx,lgi.nll) = inf;

        for k = reshape(g_idx,1,[])

            % ignore if masked
            if lgrid(k,lgi.ign) > 0, continue, end

            theta = [lgrid(k,lgi.C),lgrid(k,lgi.gamma)];

            se = 0; sp = 0; mcc = 0; err = ones(2,1); status = 0;

            if ~strcmpi(criterion,'rmb')
                [se,sp,mcc,err,status] = cross_validation( ...
                    problem, trainfunc, theta, testfunc, {eempfunc; enllfunc});
            end
            rmb = ermbfunc(problem.trainset, problem.trainlabels, theta);

            gm = geomean([se;sp],1);

            lgrid(k,lgi.se) = mean(se,2);
            lgrid(k,lgi.sp) = mean(sp,2);
            lgrid(k,lgi.gm) = mean(gm,2);
            lgrid(k,lgi.emp) = mean(err(1,:),2);
            lgrid(k,lgi.nll) = mean(err(2,:),2);
            lgrid(k,lgi.rmb) = rmb;
            lgrid(k,lgi.mcc) = mean(mcc,2);

            % ignore if error
            lgrid(k,lgi.ign) = status;
            % mark as tested
            lgrid(k,lgi.test) = 1;

            if mod(k,10)==0, fprintf('|'), end

        end % for k

        % cap inf values to respective max
        lgrid(find(lgrid(:,lgi.emp)==inf),lgi.emp) = max(lgrid(find(lgrid(:,lgi.emp)<inf),lgi.emp));
        lgrid(find(lgrid(:,lgi.rmb)==inf),lgi.rmb) = max(lgrid(find(lgrid(:,lgi.rmb)<inf),lgi.rmb));
        lgrid(find(lgrid(:,lgi.nll)==inf),lgi.nll) = max(lgrid(find(lgrid(:,lgi.nll)<inf),lgi.nll));

        [ii] = find(crit_sgn.*lgrid(:,crit_lgi)==max(crit_sgn.*lgrid(:,crit_lgi)));

        % print best values
        for i=1:length(ii)
            fprintf('\n> crit, logc, loggamma\t%8.6f\t%4.2f\t%4.2f\n',...
                    lgrid(ii(i),crit_lgi), log(lgrid(ii(i),lgi.C)), log(lgrid(ii(i),lgi.gamma)))
        end

        time = com.time_tick(time, 1);
        grid = gu.unpack(lgrid, gnames);

        if g < iter
            if strcmpi(strategy, 'zoom')
                grid = gt.zoom( grid, 4, crit_sgn*crit_gi, ...
                                [3:length(gnames)], gi.ign, @exp, @log);
            elseif strcmpi(strategy, 'threshold')
                grid = gt.threshold( grid, 0.9, 100, crit_sgn*crit_gi, ...
                                     [3:length(gnames)], gi.ign, @exp, @log);
            elseif strcmpi(strategy, 'nbest')
                grid = gt.nbest( grid, 4, 2, crit_sgn*crit_gi, ...
                                 [3:length(gnames)], gi.ign, @exp, @log);
            end
        end

    end % for g

    % find final best result after grid refinement
    [ii jj] = find(crit_sgn*grid.data(:,:,crit_gi) == max(max(crit_sgn*grid.data(:,:,crit_gi))));

    radius = (log(grid.param1(ii)).^2 + log(grid.param2(jj))'.^2 ) .^ 0.5;
    ri = find(radius == min(radius),1,'first');


    %%% test best-performing parameters %%%

    fprintf('#\n+ test\n+ logc\t%4.2f\n+ loggamma\t%4.2f\n',...
            log(grid.param1(ii(ri))), log(grid.param2(jj(ri))))

    res = com.test_csvm(problem,kernel,lib,grid.param1(ii(ri)),grid.param2(jj(ri)));

    % com.write_test_info(tabfile, dataset, featset, ['svm-' kernel(1:3)], ...
    %                     fmap(grid.param1(ii)), fmap(grid.param2(jj)), res, randseed);

    svm_params = log([grid.param1(ii(ri)),grid.param2(jj(ri))]);

    com.print_test_info(res);
    com.time_tick(time,0);

end
