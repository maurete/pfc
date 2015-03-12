function [nhparam,nh,res,names] = select_model_mlp ( problem, criterion, method, repeat )

    com = common;

    if nargin < 4 || isempty(repeat), repeat = 1; end
    if nargin < 3 || isempty(method), method = 'trainscg'; end
    if nargin < 2 || isempty(criterion), criterion = 'gm'; end

    % error names
    names = { 'se'      , ... % sensitivity
              'sp'      , ... % specificity
              'gm'      , ... % gm
              'emp'     , ... % empirical error (Adankon et al.)
              'nll'     , ... % negative log likelihood (Glasmachers & Igel; Keerthi et al.)
              'mcc'       ... % Matthews Correlation Coefficient
            };
                              %              'rmb'     , ... % RMB (Chung et al.)

    % number of neurons in hidden layer
    nh = 0:50';

    % results matrix
    res = nan(length(nh),length(names));

    % name indexes
    ni = struct();
    for i=1:length(names), ni.(names{i}) = i; end

    crit_sgn = 1;
    crit_idx = ni.(criterion);
    if any(strcmpi(criterion, {'emp', 'nll', 'rmb'}))
        crit_sgn = -1;
    end

    % training, testing and error functions
    trainfunc = @(in,tg,th) mlp_train(in,tg,th,method);
    testfunc  = @mlp_classify;
    eerrfunc  = @(out,trg) log(sum(error_empirical(out,trg)));
    enllfunc  = @(out,trg) log(error_nll(...
        @model_sigmoid, [], model_sigmoid_train(out,trg),out,trg));

    % ermbfunc  = @(in,tg,th) log(error_rmb_csvm( ...
    %     trainfunc, theta, 1, false, input, target));

    time = com.time_init();
    time = com.time_tick(time, 1);

    %%% grid-search %%%

    for k = 1:length(nh)

        theta = nh(k);

        %stat = struct();
        out = nan(sum(problem.partitions.validation(:)), repeat);
        for r = 1:repeat
            [out(:,r),tar,~,~,s] = cross_validation( ...
                problem, trainfunc, theta, testfunc);
            stat(r)=s;
        end

        %rmb = ermbfunc(problem.trainset, problem.trainlabels, theta);
        emp = eerrfunc(mean(out,2),tar);
        nll = enllfunc(mean(out,2),tar);

        res(k,ni.se) = mean([stat.se]);
        res(k,ni.sp) = mean([stat.sp]);
        res(k,ni.gm) = mean([stat.gm]);
        res(k,ni.mcc) = mean([stat.mc]);
        res(k,ni.emp) = emp;
        res(k,ni.nll) = nll;

        if mod(k,10) == 0, fprintf('|'), else fprintf('.'), end

    end % for k

    [ii] = find(crit_sgn.*res(:,crit_idx)==max(crit_sgn.*res(:,crit_idx)),1,'first');
    nhparam = nh(ii)

    % % print best values
    % for i=1:length(ii)
    %     fprintf('\n> crit, logc, loggamma\t%8.6f\t%4.2f\t%4.2f\n',...
    %             lgrid(ii(i),crit_lgi), log(lgrid(ii(i),lgi.C)), log(lgrid(ii(i),lgi.gamma)))
    % end
    time = com.time_tick(time, 1);

    figure
    hold all
    h = [];
    l = {};
    for i=1:length(names)
        h = [h plot(nh, res(:,i))];
    end
    legend(h,names)
    xlabel( '#hidden' )
    hold off

    % % find final best result after grid refinement
    % [ii] = find(crit_sgn*res(:,crit_gi) == max(max(crit_sgn*res(:,crit_gi))),1,'first');

    % %%% test best-performing parameters %%%

    % fprintf('#\n+ test\n+ logc\t%4.2f\n+ loggamma\t%4.2f\n',...
    %         log(grid.param1(ii(ri))), log(grid.param2(jj(ri))))

    res = problem_test(problem,'mlp',nhparam,method,repeat);

    % % com.write_test_info(tabfile, dataset, featset, ['svm-' kernel(1:3)], ...
    % %                     fmap(grid.param1(ii)), fmap(grid.param2(jj)), res, randseed);

    % svm_params = log([grid.param1(ii(ri)),grid.param2(jj(ri))]);

    com.print_test_info(res);
    com.time_tick(time,0);

end
