function model = mysvm_train(lib,kfun,samples,labels,boxconstraint,...
                             kfun_param,autoscale,tolkkt,prob_estimates)
%MYSVM_TRAIN Train a support vector machine model.
%
%   MODEL = MYSVM_TRAIN(LIB,KERNELFUNC,SAMPLES,LABELS) trains an SVM
%     model using library LIB and kernel function name KERNELFUNC,
%     with the data present in SAMPLES and corresponding LABELS,
%     wih default parameters.
%     LIB can be either 'matlab' for using Bioinformatics Toolbox
%     functions, or 'libsvm' for libSVM's Matlab interface.
%     KERNELFUNC can be either a kernel function handle, or the
%     strings 'linear' for a linear kernel or 'rbf' for an RBF kernel.
%     SAMPLES is a matrix whose rows represent training vectors, and
%     LABELS is a column vector with corresponding classes. For now,
%     only +1/-1 values are supported only for LABELS.
%     Output MODEL is a struct with the support vectors and all other
%     information required to classify new data with the function
%     MYSVM_CLASSIFY.
%
%  MODEL = MYSVM_TRAIN(...,BOXCONSTRAINT,KERNEL_PARAMS,AUTOSCALE,...
%                      TOL,PROB_ESTIMATES) sets non-default parameters
%     for training. BOXCONSTRAINT is the SVM 'C' parameter (default=1),
%     KERNEL_PARAMS are passed on to the kernel function (default=[]),
%     AUTOSCALE enables the 'autoscale' feature in Matlab's svmtrain,
%     TOL sets the numeric tolerance for solving the SVM problem, and
%     PROB_ESTIMATES enables posterior probability estimates feature
%     in libSVM's svmtrain.
%
%   See also MYSVM_CLASSIFY

    % Set missing parameters
    if nargin < 9 || isempty(prob_estimates); prob_estimates = false; end
    if nargin < 8 || isempty(tolkkt);         tolkkt         = 1e-6;  end
    if nargin < 7 || isempty(autoscale);      autoscale      = false; end
    if nargin < 6 || isempty(kfun_param);     kfun_param     = [];    end
    if nargin < 5 || isempty(boxconstraint);  boxconstraint  = 1;     end

    config; % Load global settings

    % Number of positive, negative, all samples
    Nplus  = sum(labels>0);
    Nminus = sum(labels<0);
    N      = length(labels);

    % Box constraint weighed for number of samples of each class
    Cplus  = boxconstraint*(N/(2*Nplus));
    Cminus = boxconstraint*(N/(2*Nminus));

    %% SVM model training

    if strncmpi(lib, 'matlab', 6)
        % If matlab classifier selected, remove libsvm from path
        if isempty(strfind(which('svmtrain'),'bioinfo')), rmpath(LIBSVM_DIR); end
        assert(any(strfind(which('svmtrain'),'bioinfo')), ...
               'mysvm_train: failed to load Matlab Bioinfo svmtrain.')

        % Kernel matrix size for SMO algorithm cache
        cache_size = 5000;

        % SMO options
        smoopts = statset('MaxIter',50000);

        % Train model and set kernel_function handle
        if isa(kfun,'function_handle')
            % kfun is already a function handle
            model = svmtrain( samples, labels, ...
                              'boxconstraint', boxconstraint, ...
                              'autoscale', autoscale, ...
                              'tolkkt', tolkkt, ...
                              'options', smoopts, ...
                              'kernel_function', @(x,y) kfun(x,y,kfun_param));
            kernel_function = kfun;

        elseif isa(kfun,'char')
            % Choose kernel function for known kernels
            if strcmp(kfun, 'rbf')
                % RBF kernel selected
                model = svmtrain( samples, labels, ...
                                  'boxconstraint', boxconstraint, ...
                                  'autoscale', autoscale, ...
                                  'tolkkt', tolkkt, ...
                                  'options', smoopts, ...
                                  'kernel_function', @(x,y) kernel_rbf(x,y,kfun_param));
                kernel_function = @kernel_rbf;

            elseif strcmp(kfun, 'linear')
                % Linear kernel selected.
                model = svmtrain( samples, labels, ...
                                  'boxconstraint', boxconstraint, ...
                                  'autoscale', autoscale, ...
                                  'tolkkt', tolkkt, ...
                                  'options', smoopts, ...
                                  'kernel_function', @kernel_linear);
                kernel_function = @kernel_linear;

            else
                % Kernel function name is unknown
                error( 'mysvm_train: selected kernel not recognized: %s.\n', kfun );
            end

        end

        % Set custom fields on output structure
        model.sv_     = model.SupportVectors;
        model.nsv_    = length(model.SupportVectorIndices);
        model.svi_    = model.SupportVectorIndices;
        model.alpha_  = model.Alpha;
        model.bias_   = model.Bias;
        model.lib_    = 'matlab';
        model.tolkkt_ = tolkkt;
        model.cache_  = cache_size;

    elseif strncmpi(lib, 'libsvm', 6)
        % If libsvm selected, assert it is loaded in path
        if isempty(strfind(which('svmtrain'),'libsvm')), addpath(LIBSVM_DIR); end
        assert(any(strfind(which('svmtrain'),'libsvm')), ...
               'mysvm_train: failed to load libSVM svmtrain.')

        % Max memory used for training
        cache_size = 200;

        % Set common svmtrain options
        optstr = sprintf(' -c %f -w1 %f -w-1 %f -e %f -m %d -b %d -q ', ...
                         boxconstraint, ... % box constraint
                         N/(2*Nplus), N/(2*Nminus), ... % class weights
                         tolkkt, cache_size, prob_estimates );

        if isa(kfun,'function_handle')
            % kfun is a function handle, should pass it as a precomputed matrix
            K1 = [[1:size(samples,1)]', kfun(samples,samples,kfun_param)];
            model = svmtrain(labels, K1, [' -t 4 ', optstr]);
            kernel_function = kfun;

        elseif isa(kfun,'char')
            % Choose kernel function for known kernels
            if strcmp(kfun, 'rbf')
                % RBF kernel selected
                model = svmtrain(labels,samples,[' -t 2 ', optstr, ...
                                    ' -g ', num2str(kfun_param)]);
                kernel_function = @kernel_rbf;

            elseif strcmp(kfun, 'linear')
                % linear kernel selected
                model = svmtrain(labels, samples, [' -t 0 ', optstr]);
                kernel_function = @kernel_linear;

            else
                % Kernel function name is unknown, raise error
                error( 'mysvm_train: selected kernel not recognized: %s.\n', kfun );
            end

        end

        % Set custom fields on output structure
        model.sv_     = full(model.SVs);
        if (exist('K1')==1), model.sv_ = samples(model.SVs,:); end
        model.nsv_    = model.totalSV;
        model.svi_    = model.sv_indices;
        model.alpha_  = model.sv_coef;
        model.bias_   = model.rho;
        model.lib_    = 'libsvm';
        model.tolkkt_ = tolkkt;
        model.cache_  = cache_size;

    else
        % Library name is unknown, raise error
        error('mysvm_train: selected library %s not recognized.\n', lib);
    end

    %% Set extra output information

    % In calculations it is assumed that sign(alpha) == class(sv)
    if sign(model.alpha_)'*labels(model.svi_) < 0,
        model.alpha_ = -model.alpha_;
    end

    % Find free and bounded support vectors
    sviplus  = labels(model.svi_) > 0;
    sviminus = labels(model.svi_) < 0;
    bsv = false(size(model.svi_));
    bsv(sviplus)  = abs(model.alpha_(sviplus))  >= Cplus-tolkkt;
    bsv(sviminus) = abs(model.alpha_(sviminus)) >= Cminus-tolkkt;

    % Extra model information
    model.bsv_     = bsv;
    model.nbsv_    = sum(bsv);
    model.cplus_   = Cplus;
    model.cminus_  = Cminus;
    model.svclass_ = labels(model.svi_);
    model.kernel_  = kfun;
    model.kfunc_   = kernel_function;
    model.C_       = boxconstraint;
    model.kparam_  = kfun_param;

    %% Validation checks

    % sum(alpha*y) should be zero
    if abs(sum(model.alpha_)) > tolkkt,
        warning('sum(alpha*y) = %f', sum(model.alpha_))
    end

    % The sign of alpha should be in accordance with SV class
    if any(sign(model.alpha_) ~= model.svclass_),
        warning('sign(alpha_i) != class(sv_i)')
    end

    % There should be at least one bounded support vector
    % if model.nbsv_ == 0,
    %     warning('no bounded vectors: c+=%f, c-=%f, max(alpha)=%f, min(alpha)=%f', ...
    %             Cplus, Cminus, max(model.alpha_), min(model.alpha_))
    % end

end
