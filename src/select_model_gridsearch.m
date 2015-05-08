function [svm_params,grid,res,ntrain,out] = select_model_gridsearch ( problem, feats, kernel, lib, iter, ...
                                                      criterion, strategy, svm_tol, grid0, fast )

    %% Initialization

    if nargin < 10 || isempty(fast), fast = false; end
    % default initial values
    if nargin < 8 || isempty(svm_tol), svm_tol = 1e-6; end
    if nargin < 7 || isempty(strategy), strategy = 'threshold'; end
    if nargin < 6 || isempty(criterion), criterion = 'gm'; end
    if nargin < 5 || isempty(iter), iter = 3; end

    % setup grid range
    if nargin < 9 || isempty(grid0)
        % initial grid parameters (from Hsu et al.)
        box0 = log(pow2([-5:2:15]));
        gam0 = 0;

        % if RBF kernel, set initial gamma range
        if get_kernel(kernel, 'rbf', false)
            gam0 = log(pow2([-15:2:3]));
        end

        % create grid
        grid = grid_new(box0, gam0);
    else
        grid = grid0;
    end

    % grid layer names
    for i=1:length(grid.name), gi.(grid.name{i}) = i; end

    % training function
    trainfunc = @(input,target,theta) mysvm_train( ...
        lib, kernel, input, target, theta(1), theta(2:end) ...
        );

    % test/validation function
    testfunc = @(model, input) model_csvm( ...
        model, input, ...
        true ... % decision values (true), binary output (false)
        );

    % empirical error function
    eempfunc = @(output, target) sum(error_empirical(output, target));

    % RMB error function
    ermbfunc = @(input, target, theta) error_rmb_csvm( ...
        trainfunc, theta, ...
        1, ... % Delta
        false, ... % log-space parameter for derivatives (unused)
        input, target);

    % features indexes
    features = featset_index(feats);

    % criterion for max(min)imisation
    crit = gi.(lower(criterion)); csgn = 1;
    if any(strcmp(criterion, {'emp', 'rmb', 'er'})), csgn = -1; end

    % timer
    time = time_init();
    time = time_tick(time, 1);

    %%% Grid-search %%%

    for g = 1:iter

        lg = grid_linearize(grid);

        % select elements to be tested
        [idx] = find(1-[lg.data(:,gi.test)|lg.data(:,gi.ign)]);

        fprintf('#\n> gridsearch iteration\t%g\n> parameters\t%d\n', ...
                g, numel(idx));

        % set error values to inf/max
        lg.data(idx,gi.emp) = inf;
        lg.data(idx,gi.rmb) = inf;
        lg.data(idx,gi.er)  = 1;

        % for each parameter set
        for k = reshape(idx,1,[])

            % ignore if masked
            if lg.data(k,gi.ign) > 0, continue, end

            theta = exp(lg.params(k,:));

            % do cross validation
            [out,trg,~,~,stat] = cross_validation( ...
                problem, feats, trainfunc, theta, testfunc );

            % obtain empirical and rmb-errors
            if ~fast
                emp = eempfunc(out,trg);
                rmb = ermbfunc(problem.traindata(:,features), problem.trainlabels, theta);
            end
            if stat.status == 0
                % if there's no error, save back results
                m = {'se', 'sp', 'gm', 'er', 'fm', 'mc'};
                for i=1:length(m)
                    lg.data(k,gi.(m{i})) = stat.(m{i});
                end
                if ~fast
                    lg.data(k,gi.emp) = emp;
                    lg.data(k,gi.rmb) = rmb;
                end
            else
                % ignore if error
                lg.data(k,gi.ign) = 1;
            end

            % mark as tested
            lg.data(k,gi.test) = 1;

            if mod(k,10)==0, fprintf('|'), end

        end % for k

        % cap inf values to respective max
        for i = [gi.emp, gi.rmb]
            einf = lg.data(:,i)==inf;
            if ~fast, lg.data(einf,i) = max(lg.data(~einf,i)); end
        end

        [bi] = find(csgn.*lg.data(:,crit)==max(csgn.*lg.data(:,crit)));

        % print best values
        for i=1:length(bi)
            fprintf('\n> crit, logc, loggamma\t%8.6f\t%4.2f\t%4.2f\n',...
                    lg.data(bi(i),crit), lg.params(bi(i),:))
        end

        % count time taken for this iteration
        time = time_tick(time, 1);

        grid = grid_repack(lg);

        % refine the grid according to strategy
        if g < iter
            if strcmpi(strategy, 'zoom')
                grid = grid_zoom( grid, ...
                                  2, ... % zoom factor
                                  csgn*crit, ... % criterion
                                  [3:length(grid.name)], ... % interpolate
                                  gi.ign ... % ignore
                                  );

            elseif strcmpi(strategy, 'threshold')
                grid = grid_threshold( grid, ...
                                       0.9, ... % keep only 10%
                                       100, ... % up to a max of 100
                                       csgn*crit, ... % criterion
                                       [3:length(grid.name)], ... % interpolate
                                       gi.ign ... % ignore
                                       );
            elseif strcmpi(strategy, 'nbest')
                grid = grid_nbest( grid, ...
                                   5, ... % detail around 10 best values
                                   2, ... % with detail 0.5
                                   csgn*crit, ... % criterion
                                   [3:length(grid.name)], ... % interp
                                   gi.ign ... % ignore
                                   );
            end
        end

    end % for g

    %% Results

    % find final best result after grid refinement
    [bi] = find(csgn.*lg.data(:,crit)==max(csgn.*lg.data(:,crit)));

    % if many elements choose the one closest to (0,0)
    radius = sum([lg.params(bi,:).^2],2) .^ 0.5;
    ri = find(radius == min(radius),1,'first');

    % return best parameters
    svm_params = lg.params(bi(ri),1);
    if get_kernel(kernel,'rbf', false)
        svm_params = [svm_params lg.params(bi(ri),2)];
    end

    fprintf('#\n+ test\n+ logc\t%4.2f\n',svm_params(1))
    if numel(svm_params) > 1
        fprintf('+ loggamma\t%4.2f\n', svm_params(2))
    end

    % Generate output model
    out = struct();
    out.features = features;
    out.trainfunc = @(in,tg) mysvm_train( lib, kernel, in, tg, ...
            exp(svm_params(1)), exp(svm_params(2:end)), svm_tol );
    out.classfunc = @mysvm_classify;
    out.trainedmodel = mysvm_train( lib, kernel, problem.traindata(:,features), ...
                                    problem.trainlabels, exp(svm_params(1)), ...
                                    exp(svm_params(2:end)), svm_tol );

    % get test results for this problem
    res = problem_test(problem,feats,lib,kernel,exp(svm_params(1)),exp(svm_params(2:end)));
    print_test_info(res);
    time_tick(time,0);

    ntrain = numel(find(grid.data(:,:,gi.test)));

end
