function [best,out,hid,res,names] = select_model_mlp( problem, feats, criterion, method, repeat, disp, fann)

    if nargin < 7 || isempty(fann), fann = false; end
    if nargin < 6 || isempty(disp), disp = true; end
    if nargin < 5 || isempty(repeat), repeat = 5; end
    if nargin < 4 || isempty(method), method = 'trainrp'; end
    if nargin < 3 || isempty(criterion), criterion = 'gm'; end

    % error names
    names = { 'se'      , ... % sensitivity
              'sp'      , ... % specificity
              'gm'      , ... % gm
              'emp'     , ... % empirical error (Adankon et al.)
              'nll'     , ... % negative log likelihood (Glasmachers & Igel; Keerthi et al.)
              'mcc'       ... % Matthews Correlation Coefficient
            };

    features = featset_index(feats);

    % number of neurons in hidden layer
    nh = 0:max([10, round(numel(features)*0.7)]);

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
    trainfunc = @(in,tg,vi,vt,th) mlp_xtrain(in,tg,vi,vt,th,method,[],fann);
    testfunc  = @mlp_classify;
    eerrfunc  = @(out,trg) log(sum(error_empirical(out,trg)));
    enllfunc  = @(out,trg) log(error_nll(...
        @model_sigmoid, [], model_sigmoid_train(out,trg),out,trg));

    time = time_init();
    time = time_tick(time, 1);

    %%% grid-search %%%

    for k = 1:length(nh)

        theta = [nh(k) nh(k)];

        %stat = struct();
        out = nan(sum(problem.partitions.validation(:)), repeat);
        for r = 1:repeat
            [out(:,r),tar,~,~,s] = cross_validation( ...
                problem, feats, trainfunc, theta, testfunc,[],true);
            stat(r)=s;
        end

        emp = nan;%eerrfunc(mean(out,2),tar);
        nll = nan;%enllfunc(mean(out,2),tar);

        res(k,ni.se) = mean([stat.se]);
        res(k,ni.sp) = mean([stat.sp]);
        res(k,ni.gm) = mean([stat.gm]);
        res(k,ni.mcc) = mean([stat.mc]);
        res(k,ni.emp) = emp;
        res(k,ni.nll) = nll;

        if mod(k,10) == 0, fprintf('|'), else fprintf('.'), end

    end % for k

    [ii] = find(abs(crit_sgn.*res(:,crit_idx)-max(crit_sgn.*res(:,crit_idx)))<1e-5,1,'first');
    best = nh(ii)

    time = time_tick(time, 1);

    if disp
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
    end

    time_tick(time,0);

    hid = nh;

    % Generate trained output model
    out = struct();
    out.features = features;
    out.trainfunc = @(in,tg) mlp_xtrain(in,tg,[],[],best,method,[],fann);
    out.classfunc = @mlp_classify;
    out.trainedmodel = {};
    for i=1:repeat
        out.trainedmodel{i} = mlp_xtrain(problem.traindata(:,features), ...
                                         problem.trainlabels,[],[],best,...
                                         method,[],fann);
    end

end
