function [model,results] = select_model(problem, feats, classifier, method, varargin)

    if nargin < 1 || ~isstruct(problem), error('No problem given.'), end
    if nargin < 2 || isempty(feats), feats = 8; end
    if nargin < 3 || isempty(classifier), classifier = 'rbf'; end
    if nargin < 4 || isempty(method), method = 'rmb'; end

    classifier = lower(classifier);
    method = lower(method);

    LIBSVM_DIR = './libsvm-3.20/matlab/';

    % default options
    verbose = true;
    svmlib  = 'libsvm';
    gs_crit = 'gm';
    gs_stgy = 'threshold';
    gs_iter = 3;
    mlp_crit = [];
    mlp_bckp = [];
    mlp_nrep = [];

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
           if strcmpi(opts{i},'Verbose')
               i = i+1;
               verbose = opts{i};
           elseif strcmpi(opts{i},'SVMLib')
               i = i+1;
               svmlib = opts{i};
           elseif strcmpi(opts{i},'GridSearchCriterion')
               i = i+1;
               gs_crit = lower(opts{i});
           elseif strcmpi(opts{i},'GridSearchStrategy')
               i = i+1;
               gs_stgy = lower(opts{i});
           elseif strcmpi(opts{i},'GridSearchIterations')
               i = i+1;
               gs_iter = opts{i};
           elseif strcmpi(opts{i},'MLPCriterion')
               i = i+1;
               mlp_crit = lower(opts{i});
           elseif strcmpi(opts{i},'MLPBackPropagation')
               i = i+1;
               mlp_bckp = lower(opts{i});
           elseif strcmpi(opts{i},'MLPNRepeats')
               i = i+1;
               mlp_nrep = opts{i};
           end
       end
       i = i+1;
    end

    if strcmpi(svmlib,'libsvm') && ~strcmpi(classifier,'mlp')
        if isempty(strfind(lower(which('svmtrain')),'libsvm'))
            addpath(LIBSVM_DIR);
            if isempty(strfind(lower(which('svmtrain')),'libsvm'))
                warning('Unable to load libSVM: will use matlabs bioinfo svm instead.')
                svmlib = 'matlab';
            end
        end
    end
    if strcmpi(method,'rmb')
        if isempty(strfind(lower(which('svmtrain')),'libsvm'))
            addpath(LIBSVM_DIR);
            if isempty(strfind(lower(which('svmtrain')),'libsvm'))
                warning('Unable to load libSVM: RMB method unavailable, using empirical error instead.')
                method = 'empirical';
            end
        end
    end


    % do model selection
    if strcmpi(classifier,'mlp')
        [params,~,~,~,res,model] = select_model_mlp(problem,feats,mlp_crit,mlp_bckp,mlp_nrep,false);
    else
        if strcmpi(method,'rmb')
            assert(any(strfind(classifier,'rbf')),'RMB can only be used with an RBF kernel.')
            [params,~,~,res,~,model] = select_model_rmb(problem,feats,'rbf',svmlib);
        elseif strcmpi(method,'empirical')
            [params,~,~,res,~,model] = select_model_empirical(problem,feats,classifier,svmlib);
        elseif strcmpi(method,'trivial')
            [params,res,model] = select_model_trivial(problem,feats,classifier,svmlib);
        elseif strcmpi(method,'gridsearch')
            [params,~,res,~,model] = select_model_gridsearch(problem,feats,classifier,svmlib,...
                                                             gs_iter, gs_crit, gs_stgy, ...
                                                             [],[], true);
        end
    end

    results = res;

end
