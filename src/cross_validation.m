function [se,sp,mcc,err,ret] = cross_validation ( problem, trainfunc, args, clsfunc, errfunc)

    if nargin < 5 || isempty(errfunc), errfunc = {}; end
    if nargin > 4 && ~isa(errfunc, 'cell'), errfunc = {errfunc}; end

    % validate partition size
    if size(problem.partitions.train,1) < 1
        error('Training partitions cannot be empty.')
    end
    if size(problem.partitions.validation,1) < 1
        error('Validation partitions cannot be empty.')
    end

    randseed = problem.randseed;
    part = problem.partitions;
    npart = problem.npartitions;

    com = common;
    com.init_matlabpool();

    se  = 0;
    sp  = 0;
    mcc = 0;
    err = inf(length(errfunc),1);

    ret = 0; % 0=OK, <>0=ERROR

    output = nan(size(problem.partitions.validation))';
    ntrain = size(problem.trainset,1);

    parfor p = 1:npart %partitions

        trainset    = problem.trainset(part.train(:,p),:);
        valset      = problem.trainset(part.validation(:,p),:);
        trainlabels = problem.trainlabels(part.train(:,p));
        vallabels   = problem.trainlabels(part.validation(:,p));

        try
            model = trainfunc(trainset, trainlabels, args);
            tmp = zeros(ntrain,1);
            tmp(part.validation(:,p)) = clsfunc(model, valset);
            output(p,:) = tmp';

        catch e
            if any(strfind(e.identifier,'NoConvergence')) || ...
                    any(strfind(e.identifier,'InvalidInput'))
                ret = 1;
            else
                rethrow(e);
            end
        end
    end

    if ret > 0, return, end

    output = output';
    target = repmat(problem.trainlabels,1,npart);

    output = output(part.validation);
    target = target(part.validation);

    tp = sum(output(target>0)>0);
    fp = sum(output(target<0)>0);
    tn = sum(output(target<0)<0);
    fn = sum(output(target>0)<0);

    se  = tp/(tp+fn);
    sp  = tn/(fp+tn);
    mcc = (tp*tn-fp*fn)/sqrt((tp+fp)*(tp+fn)*(tn+fp)*(tn+fn));

    for i=1:length(errfunc)
        try, err(i) = errfunc{i}(output, target);
        catch e, warning('%s: %s', e.identifier, e.message); ret = 2;
        end
    end

end
