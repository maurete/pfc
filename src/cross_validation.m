function [output,target,deriv,index,stat] = cross_validation( problem, ftrain, args, fcls, fclsderiv)
    do_deriv = false;
    if nargin < 5, fclsderiv = false; end
    if nargin > 4 && isa(fclsderiv,'function_handle'), do_deriv = true; end

    % validate partition size
    if size(problem.partitions.train,1) < 1
        error('Training partitions cannot be empty.')
    end
    if size(problem.partitions.validation,1) < 1
        error('Validation partitions cannot be empty.')
    end

    part  = problem.partitions;
    npart = problem.npartitions;

    com = common;
    com.init_matlabpool();

    ret = 0; % 0=OK, <>0=ERROR

    ntrain = size(problem.trainset,1);
    nargs  = length(args);
    output = nan(size(problem.partitions.validation))';
    deriv  = nan(npart,ntrain*nargs);

    parfor p = 1:npart %partitions

        trainset    = problem.trainset(part.train(:,p),:);
        valset      = problem.trainset(part.validation(:,p),:);
        trainlabels = problem.trainlabels(part.train(:,p));
        vallabels   = problem.trainlabels(part.validation(:,p));

        try
            model = ftrain(trainset, trainlabels, args);
            tmp = zeros(ntrain,1);
            tmp(part.validation(:,p)) = fcls(model, valset);
            output(p,:) = tmp';

            if do_deriv
                tmp = nan(ntrain,nargs);
                tmp(part.validation(:,p),:) = fclsderiv(model, valset);
                %tmp(part.validation(:,p),:) = ones([length(find(part.validation(:,p))),nargs])*diag(args);
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

    stat = struct();
    stat.status = ret;

    output = output';
    target = repmat(problem.trainlabels,1,npart);
    output = output(part.validation);
    target = target(part.validation);
    dtmp = zeros(length(output),nargs);
    deriv  = deriv';
    for i=1:nargs
        dtmp(:,i) = deriv([ repmat(part.validation&0,i-1,1); ...
                            part.validation; ...
                            repmat(part.validation&0,nargs-i,1)]);
    end
    deriv = dtmp;
    index  = mod(find(part.validation)-1,ntrain)+1;

    np = sum(target > 0); % number of positive examples
    nn = sum(target < 0); % number of negative examples

    tp = sum(output(target>0)>0); % true positives
    fp = sum(output(target<0)>0); % false positives
    tn = sum(output(target<0)<0); % true negatives
    fn = sum(output(target>0)<0); % false negatives

    mcc = (tp*tn-fp*fn)/sqrt((tp+fp)*(tp+fn)*(tn+fp)*(tn+fn));

    stat.er = (np-tp+fp)/(np+nn); % error rate
    stat.pr = tp/(tp+fp); % precision
    stat.se = tp/(tp+fn); % sensitivity (recall)
    stat.sp = tn/(fp+tn); % specificity
    stat.gm = geomean([stat.se stat.sp]); % geometric mean of SE,SP
    stat.fm = 2*tp/(np+tp+fp); % F-measure
    stat.mc = mcc; % Matthews Correlation Coefficient

end
