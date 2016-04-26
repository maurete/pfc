function [model,nt] = select_model(problem, feats, classifier, method, varargin)
%SELECT_MODEL Perform model selection.
%
%  MODEL = SELECT_MODEL(PROBLEM, FEATS, CLASSIFIER, METHOD) performs model
%  selection for PROBLEM. PROBLEM is a problem struct as returned by
%  PROBLEM_GEN, and must contain a valid trainig dataset. FEATS is the feature
%  set index as returned by the FEATSET_INDEX private function, most commonly
%  the values 8 for sequence and secondary structure features, or 5 for the
%  secondary structure features only. CLASSIFIER is a string with possible
%  values 'mlp' for multilayer perceptron, 'svm-linear' for SVM with linear
%  kernel, and 'svm-rbf' for SVM with RBF kernel. METHOD is the SVM model
%  selection method to be used: 'trivial' for the trivial method, 'gridsearch'
%  for grid search, 'empirical' for the empirical error criterion, or 'rmb' for
%  the radius margin-like bound, available for 'svm-rbf' classifier only. The
%  value of 'method' is ignored for the MLP classifier.
%  MODEL is the trained model with the optimal parameters found.
%
%  NT is the number of trainings performed during model optimization.
%
%  MODEL = SELECT_MODEL(..., OPTIONS) sets additional options as a comma-
%  separated list of options:
%    * 'Verbose', <LOGICAL> : sets verbose flag on or off (default=true),
%    * 'SVMLib', <STRING> : either 'libsvm' or 'matlab' for selecting the
%        SVM toolbox to be used (default='libsvm'),
%    * 'GridSearchCriterion', <STRING> : sets the performance criteria to be
%        optimized by the grid search method (default='gm'),
%    * 'GridSearchStrategy', <STRING> : sets the grid refinement strategy to be
%        used by the grid search method (default='threshold'),
%    * 'GridSearchIterations', <REAL> : sets the # of grid refinement
%        iterations to be performed by the grid search method (default=3),
%    * 'MLPCriterion', <STRING> : sets the performance criteria to be
%        optimized by the mlp model selection method,
%    * 'MLPBackPropagation', <STRING> : sets the back propagation method to be
%        used by the mlp model selection method,
%    * 'MLPNRepeats', <REAL> : sets the number of networks to be trained by the
%        mlp model selection method.
%
%  See also PROBLEM_GEN, SELECT_MODEL_MLP, SELECT_MODEL_TRIVIAL,
%           SELECT_MODEL_GRIDSEARCH, SELECT_MODEL_EMPIRICAL, SELECT_MODEL_RMB.
%

    if nargin < 1 || ~isstruct(problem), error('No problem given.'), end
    if nargin < 2 || isempty(feats), feats = 8; end
    if nargin < 3 || isempty(classifier), classifier = 'rbf'; end
    if nargin < 4 || isempty(method), method = 'rmb'; end

    config; % load global config

    classifier = lower(classifier);
    method = lower(method);

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

    % parse extra options
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

    % load libsvm path if requested, else fallback to matlab
    if strcmpi(svmlib,'libsvm') && ~strcmpi(classifier,'mlp')
        if isempty(strfind(lower(which('svmtrain')),'libsvm'))
            addpath(LIBSVM_DIR);
            if isempty(strfind(lower(which('svmtrain')),'libsvm'))
                warning('Unable to load libSVM: will use Matlab''s ', ...
                        'Bioinformatics Toolbox SVM functions instead.')
                svmlib = 'matlab';
            end
        end
    end

    % check wether RMB method can be used (libsvm is available)
    if strcmpi(method,'rmb')
        if isempty(strfind(lower(which('svmtrain')),'libsvm'))
            addpath(LIBSVM_DIR);
            if isempty(strfind(lower(which('svmtrain')),'libsvm'))
                warning('Unable to load libSVM: RMB method unavailable, ', ...
                        'using empirical error creiterion method instead.')
                method = 'empirical';
                % if RBF was not explicitly set, fall back to linear kernel
                if nargin < 2, classifier = 'linear'; end
            end
        end
    end

    % number of trainings
    nt = nan;

    % invoke respective model selection methods
    if strcmpi(classifier,'mlp')
        [params,model,nt] = select_model_mlp(...
            problem,feats,mlp_crit,mlp_bckp,mlp_nrep, ...
            false, ... % disp
            false, ... % fann
            strcmpi(method,'trivial') ... % trivial
            );
    else
        if strcmpi(method,'rmb')
            % validate RBF kernel is being used
            assert(any(strfind(classifier,'rbf')), ...
                   'RMB can only be used with an RBF kernel.')
            [params,model,~,~,nt] = select_model_rmb(problem,feats,'rbf',svmlib);
        elseif strcmpi(method,'empirical')
            [params,model,~,~,nt] = select_model_empirical(...
                problem,feats,classifier,svmlib);
        elseif strcmpi(method,'trivial')
            [params,model] = select_model_trivial(...
                problem,feats,classifier,svmlib);
            nt = 0;
        elseif strcmpi(method,'gridsearch')
            [params,model,~,nt] = select_model_gridsearch(...
                problem, feats, classifier, svmlib, ...
                gs_iter, gs_crit, gs_stgy, [], [], true);
        end
    end

end
