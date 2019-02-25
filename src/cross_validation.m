function [output,target,deriv,index,stat,models] = cross_validation(...
    problem, feats, ftrain, args, fcls, fclsderiv, xtrain)
%CROSS_VALIDATION Perform cross-validation training on problem
%
%   [OUTPUT,TARGET,...] = CROSS_VALIDATION(PROBLEM,FEATS,FTRAIN,ARGS,FCLS)
%     Trains a classifier with crossval partitions in PROBLEM. PROBLEM is
%     a struct as returned by PROBLEM_GEN. FEATS is an index vector which
%     selects features to be considered in training. FTRAIN is a handle for
%     the training function, which must accept as first argument a data
%     matrix with samples in rows, the corresponding labels (as a column
%     vector) as second argument, and ARGS as third argument. FTRAIN must
%     return as first output a trained 'model', of whatever type accepted
%     by FCLS. FCLS is a handle for a classifying function which receives
%     the trained model as first argument, and a data matrix where each
%     row represents a sample to be classified. It must return a column
%     vector with the predicted class for each sample.
%
%   [...,DERIV] = CROSS_VALIDATION(...,FCLSDERIV) calculates the derivative
%     of validation samples in addition to predicted class. FCLSDERIV is a
%     handle for the derivative function, which receives the same inputs as
%     FCLS and returns a matrix where the ith row represents the derivative
%     of the ith validation sample w.r.t. each one of the training arguments
%     as received in the ARGS input.
%
%   [...] = CROSS_VALIDATION(...,XTRAIN)
%     When XTRAIN is set to true, it indicates that the training function
%     also receives a validation set and respective validation labels, in
%     addition to the training set, training labels, and training arguments.
%     This is useful for training functions that use this extra data as a
%     train-stopping criterion. Even when XTRAIN is set, validation set
%     classification is performed with the FCLS argument function.
%
%   [...,INDEX] = CROSS_VALIDATION(...) returns in INDEX the indices of
%     every sample classified in OUTPUT/TARGET/DERIV.
%
%   [...,STAT] = CROSS_VALIDATION(...) returns a struct with statistics of
%     the cross validation results, like error rate (.er), precision (.pr),
%     sensitivity (.se), specificity (.sp), geometric mean of sensitivity
%     and specificity (.gm), F-measure (.fm) and Matthews Correlation
%     Coefficient (.mc). These are calculated as overall measures for an
%     aggregate validation dataset, as oposed to mean values for each
%     validation partition.
%
%   [...,MODELS] = CROSS_VALIDATION(...) returns the trained models obtained
%     for each partition within a cell array.
%
%   See also PROBLEM_GEN.

    % Set default options
    do_deriv = false;
    if nargin < 7,    xtrain = false; end
    if nargin < 6, fclsderiv = false; end
    if nargin > 5 && isa(fclsderiv,'function_handle'), do_deriv = true; end

    % Validate partition sizes
    if numel(problem.partitions.train) < 1
        error('Training partitions cannot be empty.')
    end
    if numel(problem.partitions.validation) < 1
        error('Validation partitions cannot be empty.')
    end

    % Initialize pool for parallel computing
    ncores = init_parallel();
    if isempty(ncores), ncores = 1; end

    % Return value for indicating error (if ~= 0)
    ret = 0;

    % Partition information structure
    part   = problem.partitions;
    % Number of partitions
    npart  = size(problem.partitions.validation,2);
    % Number of samples in whole training set
    ntrain = size(problem.traindata,1);
    % Number of arguments to the training function
    nargs  = length(args);

    % Output variables
    output = nan(size(problem.partitions.validation))';
    deriv  = nan(npart,ntrain*nargs);
    models = cell(npart,1);

    % 'Done' flag
    done = false;

    % if octave
    if exist('OCTAVE_VERSION') ~= 0
        try
            inner_handle = @(p)cross_validation_inner_loop(p, problem, feats, args, ftrain, fcls, xtrain, do_deriv, fclsderiv);
            tmp = parcellfun(ncores,inner_handle,num2cell(1:npart), 'VerboseLevel', 0);
            for p=1:npart
                % Save results for this partition in pth row of output
                output(p,tmp(p).validation_indexes) = tmp(p).predictions';
                % Save pth model
                models{p} = tmp(p).model;

                gradtmp = nan(ntrain,nargs);
                gradtmp(tmp(p).validation_indexes,:) = tmp(p).gradient;
                % Save derivatives in pth row of deriv
                deriv(p,:) = reshape(gradtmp,1,[]);

                ret = any(tmp(p).status);
            end
            done = true;
        catch ex
        rethrow(ex)
        warning(['Unable to invoke parcellfun. ', ...
                 'Cross-validation will be run sequentially. ', ex.message])
        end
    end

    % Wrap the parfor in a try-catch statement for the case where the
    % Parallel Toolbox is unavailable
    try
        % For each partition
        parfor p = 1:npart
            tmp = cross_validation_inner_loop(p, problem, feats, args, ftrain, fcls, xtrain, do_deriv, fclsderiv);
            % Save results for this partition in pth row of output
            outtmp = nan(ntrain,1);
            outtmp(tmp.validation_indexes) = tmp.predictions';
            output(p,:) = outtmp;
            % Save pth model
            models{p} = tmp.model;

            gradtmp = nan(ntrain,nargs);
            gradtmp(tmp.validation_indexes,:) = tmp.gradient;
            % Save derivatives in pth row of deriv
            deriv(p,:) = reshape(gradtmp,1,[]);
        end
        done = true;
    catch ex
        if any(strfind(ex.identifier,'NoConvergence')) || ...
                any(strfind(ex.identifier,'InvalidInput'))
            % rethrow(ex);
            warning('No convergence on SVM training!')
        end
        warning(['Unable to run parfor. ', ...
                 'Cross-validation will be run sequentially. ', ex.message])
    end

    if ~done
        % Run sequentially when parallel options failed
        for p = 1:npart
            tmp = cross_validation_inner_loop(p, problem, feats, args, ftrain, fcls, xtrain, do_deriv, fclsderiv);
            % Save results for this partition in pth row of output
            output(p,tmp.validation_indexes) = tmp.predictions';
            % Save pth model
            models{p} = tmp.model;

            gradtmp = nan(ntrain,nargs);
            gradtmp(tmp.validation_indexes,:) = tmp.gradient;
            % Save derivatives in pth row of deriv
            deriv(p,:) = reshape(gradtmp,1,[]);
        end
    end

    % Rebuild output, target to an understandable form
    output = output';
    target = repmat(problem.trainlabels,1,npart);
    output = output(part.validation);
    target = target(part.validation);
    dtmp = zeros(length(output),nargs);

    % Rebuild derivative from linearized form
    deriv  = deriv';
    for i=1:nargs
        dtmp(:,i) = deriv([ repmat(part.validation&0,i-1,1); ...
                            part.validation; ...
                            repmat(part.validation&0,nargs-i,1)]);
    end
    deriv = dtmp;
    index = mod(find(part.validation)-1,ntrain)+1;

    % Calculate classification measures
    np = sum(target > 0); % number of positive examples
    nn = sum(target < 0); % number of negative examples
    tp = sum(output(target>0)>0); % true positives
    fp = sum(output(target<0)>0); % false positives
    tn = sum(output(target<0)<0); % true negatives
    fn = sum(output(target>0)<0); % false negatives
    mcc = (tp*tn-fp*fn)/sqrt((tp+fp)*(tp+fn)*(tn+fp)*(tn+fn));

    % Output stats structure
    stat = struct();
    stat.status = ret; % training failures for some partitions
    stat.er = (fp+fn)/(np+nn); % error rate
    stat.pr = tp/(tp+fp); % precision
    stat.se = tp/(tp+fn); % sensitivity (recall)
    stat.sp = tn/(fp+tn); % specificity
    stat.gm = geomean([stat.se stat.sp]); % geometric mean of SE,SP
    stat.fm = 2*tp/(np+tp+fp); % F-measure
    stat.mc = mcc; % Matthews Correlation Coefficient

end
