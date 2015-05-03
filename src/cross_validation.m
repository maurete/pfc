function [output,target,deriv,index,stat,models] = cross_validation( problem, feats, ftrain, args, fcls, fclsderiv, xtrain)
% CROSS_VALIDATION perform cross validation on PROBLEM by training with
% FTRAIN(args) and validating with FCLS.
% The XTRAIN argument tells wether validation data should be passed
% to FTRAIN alongside training data.
%
    do_deriv = false;
    if nargin < 7,    xtrain = false; end
    if nargin < 6, fclsderiv = false; end
    if nargin > 5 && isa(fclsderiv,'function_handle'), do_deriv = true; end

    % validate partition size
    if size(problem.partitions.train,1) < 1
        error('Training partitions cannot be empty.')
    end
    if size(problem.partitions.validation,1) < 1
        error('Validation partitions cannot be empty.')
    end

    part  = problem.partitions;
    npart = size(problem.partitions.validation,2);

    features = featset_index(feats);

    init_matlabpool();

    ret = 0; % 0=OK, <>0=ERROR

    ntrain = size(problem.traindata,1);
    nargs  = length(args);
    output = nan(size(problem.partitions.validation))';
    deriv  = nan(npart,ntrain*nargs);

    models = cell(npart,1);

    try

        parfor p = 1:npart %partitions

            trainset    = problem.traindata(part.train(:,p),features);
            valset      = problem.traindata(part.validation(:,p),features);
            trainlabels = problem.trainlabels(part.train(:,p));
            vallabels   = problem.trainlabels(part.validation(:,p));

            try
                if xtrain, model = ftrain(trainset, trainlabels, valset, vallabels, args);
                else,      model = ftrain(trainset, trainlabels, args);
                end
                tmp = zeros(ntrain,1);
                tmp(part.validation(:,p)) = fcls(model, valset);
                output(p,:) = tmp';
                models{p} = model;

                if do_deriv
                    tmp = nan(ntrain,nargs);
                    tmp(part.validation(:,p),:) = fclsderiv(model, valset);
                    deriv(p,:) = reshape(tmp,1,[]);
                end

            catch e
                if any(strfind(e.identifier,'NoConvergence')) || ...
                        any(strfind(e.identifier,'InvalidInput'))
                    ret = 1;
                else
                    rethrow(e);
                end
            end
        end

    catch e

        for p = 1:npart %partitions

            trainset    = problem.traindata(part.train(:,p),features);
            valset      = problem.traindata(part.validation(:,p),features);
            trainlabels = problem.trainlabels(part.train(:,p));
            vallabels   = problem.trainlabels(part.validation(:,p));

            try
                if xtrain, model = ftrain(trainset, trainlabels, valset, vallabels, args);
                else,      model = ftrain(trainset, trainlabels, args);
                end
                tmp = zeros(ntrain,1);
                tmp(part.validation(:,p)) = fcls(model, valset);
                output(p,:) = tmp';
                models{p} = model;

                if do_deriv
                    tmp = nan(ntrain,nargs);
                    tmp(part.validation(:,p),:) = fclsderiv(model, valset);
                    deriv(p,:) = reshape(tmp,1,[]);
                end

            catch e
                if any(strfind(e.identifier,'NoConvergence')) || ...
                        any(strfind(e.identifier,'InvalidInput'))
                    ret = 1;
                else
                    rethrow(e);
                end
            end
        end

    end

    stat = struct();
    stat.status = ret;

    output = output';
    target = repmat(problem.trainlabels,1,npart);
    output = output(part.validation);
    target = target(part.validation);
    dtmp = zeros(length(output),nargs);

    % rebuild derivative from linearized form
    deriv  = deriv';
    for i=1:nargs
        dtmp(:,i) = deriv([ repmat(part.validation&0,i-1,1); ...
                            part.validation; ...
                            repmat(part.validation&0,nargs-i,1)]);
    end
    deriv = dtmp;
    index  = mod(find(part.validation)-1,ntrain)+1;

    % calculate simple classification stats
    np = sum(target > 0); % number of positive examples
    nn = sum(target < 0); % number of negative examples

    tp = sum(output(target>0)>0); % true positives
    fp = sum(output(target<0)>0); % false positives
    tn = sum(output(target<0)<0); % true negatives
    fn = sum(output(target>0)<0); % false negatives

    mcc = (tp*tn-fp*fn)/sqrt((tp+fp)*(tp+fn)*(tn+fp)*(tn+fn));

    stat.er = (fp+fn)/(np+nn); % error rate
    stat.pr = tp/(tp+fp); % precision
    stat.se = tp/(tp+fn); % sensitivity (recall)
    stat.sp = tn/(fp+tn); % specificity
    stat.gm = geomean([stat.se stat.sp]); % geometric mean of SE,SP
    stat.fm = 2*tp/(np+tp+fp); % F-measure
    stat.mc = mcc; % Matthews Correlation Coefficient

end
