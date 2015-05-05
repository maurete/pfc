function [model,results] = best_model(problem, varargin)

    if nargin < 1 || ~isstruct(problem), error('No problem given.'), end

    % @TODO find a better function name :)

    % default options
    verbose = true;
    svmlib  = 'libsvm';
    opt_fts = [8,5];
    opt_cls = ['r','l'];
    opt_msm = ['r','e','t'];
    gs_crit = 'gm';
    gs_stgy = 'threshold';
    gs_iter = 3;

    % check if options are passed as a cell array
    opts = varargin;
    nopts = numel(varargin);
    if numel(varargin) == 1 && numel(varargin) > 0 && iscell(varargin{1})
        opts = varargin{1};
        nopts = numel(opts);
    end

    % parse options
    i=1;
    while i <= nopts
       if ischar(opts{i})
           if strcmpi(opts{i},'Features')
               i = i+1;
               opt_fts = opts{i};
           elseif strcmpi(opts{i},'Classifiers')
               i = i+1;
               opt_cls = lower(opts{i});
           elseif strcmpi(opts{i},'Methods')
               i = i+1;
               opt_msm = lower(opts{i});
           elseif strcmpi(opts{i},'Verbose')
               i = i+1;
               verbose = opts{i};
           elseif strcmpi(opts{i},'SVMLib')
               i = i+1;
               libsvm = opts{i};
           elseif strcmpi(opts{i},'GridSearchCriterion')
               i = i+1;
               gs_crit = lower(opts{i});
           elseif strcmpi(opts{i},'GridSearchStrategy')
               i = i+1;
               gs_stgy = lower(opts{i});
           elseif strcmpi(opts{i},'GridSearchIterations')
               i = i+1;
               gs_iter = opts{i};
           end
       end
       i = i+1;
    end

    % @TODO Validate input options
    % @TODO Support MLP criterion, backprop-method and n_repeats selection

    % try different features/model selection/classifiers
    results = struct();
    i = 1;
    for f = 1:numel(opt_fts)
        for c = 1:numel(opt_cls)
            for m = 1:numel(opt_msm)
                if opt_cls(c) == 'r'
                    if opt_msm(m) == 'r'
                        % @TODO skip rmb and print warning if libsvm not available
                        [params,~,~,res] = select_model_rmb(problem,opt_fts(f),'rbf',svmlib);
                        results(i) = res;
                        results(i).params = params;
                        results(i).featureset = opt_fts(f);
                        results(i).methodname = 'svm-rbf-rmb';
                        i = i+1;
                    elseif opt_msm(m) == 'e'
                        [params,~,~,res] = select_model_empirical(problem,opt_fts(f),'rbf',svmlib);
                        results(i) = res;
                        results(i).params = params;
                        results(i).featureset = opt_fts(f);
                        results(i).methodname = 'svm-rbf-empirical';
                        i = i+1;
                    elseif opt_msm(m) == 't'
                        [params,res] = select_model_trivial(problem,opt_fts(f),'rbf',svmlib);
                        results(i) = res;
                        results(i).params = params;
                        results(i).featureset = opt_fts(f);
                        results(i).methodname = 'svm-rbf-trivial';
                        i = i+1;
                    elseif opt_msm(m) == 'g'
                        [params,~,res] = select_model_gridsearch(problem,opt_fts(f),'rbf',svmlib,...
                                                                 gs_iter, gs_crit, gs_stgy, ...
                                                                 [],[], true);
                        results(i) = res;
                        results(i).params = params;
                        results(i).featureset = opt_fts(f);
                        results(i).methodname = 'svm-rbf-gridsearch';
                        i = i+1;
                    end
                elseif opt_cls(c) == 'l'
                    if opt_msm(m) == 'e'
                        [params,~,~,res] = select_model_empirical(problem,opt_fts(f),'linear',svmlib);
                        results(i) = res;
                        results(i).params = params;
                        results(i).featureset = opt_fts(f);
                        results(i).methodname = 'svm-linear-empirical';
                        i = i+1;
                    elseif opt_msm(m) == 't'
                        [params,res] = select_model_trivial(problem,opt_fts(f),'linear',svmlib);
                        results(i) = res;
                        results(i).params = params;
                        results(i).featureset = opt_fts(f);
                        results(i).methodname = 'svm-linear-trivial';
                        i = i+1;
                    elseif opt_msm(m) == 'g'
                        [params,~,res] = select_model_gridsearch(problem,opt_fts(f),'linear',svmlib,...
                                                                 gs_iter, gs_crit, gs_stgy, ...
                                                                 [],[], true);
                        results(i) = res;
                        results(i).params = params;
                        results(i).featureset = opt_fts(f);
                        results(i).methodname = 'svm-linear-gridsearch';
                        i = i+1;
                    end
                elseif opt_cls(c) == 'm'
                    [params,~,~,~,res] = select_model_mlp(problem,opt_fts(f),[],[],[],false);
                    results(i) = res;
                    results(i).params = params;
                    results(i).featureset = opt_fts(f);
                    results(i).methodname = 'mlp';
                    i = i+1;
                end
            end
        end
    end

    % compare test results and return best model
    SE = [results(:).se];
    SP = [results(:).sp];
    Gm = [results(:).gm];
    measure = Gm;
    if any(isnan(measure)), measure = SE; end
    if any(isnan(measure)), measure = SP; end
    if any(isnan(measure))
        error('No valid measure found to compare model selection results!');
    end

    bestidx = find(measure == max(measure),1,'first');

    fprintf('Best results found for feature set %d, method %s', ...
            results(bestidx).featureset, results(bestidx).methodname)

    fprintf('> SE\t%8.3f\n>SP\t%8.3f\nGm\t%8.3f\n', ...
            results(bestidx).se, results(bestidx).sp, results(bestidx).gm)

    model = results(bestidx).model;

    % @TODO Generate extensive report with results, including entry-by-entry detail
    % @TODO Generate method for extracting features and classifying new data

end
