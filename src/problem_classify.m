function out = problem_classify(problem, model)

    % perform tests on problem test datasets
    out = struct();

    nrep = 1;
    if iscell(model.trainedmodel), nrep = numel(model.trainedmodel); end

    res_se = nan(1,nrep);
    res_sp = nan(1,nrep);
    pred   = nan(numel(problem.testlabels),nrep);

    if isstruct(model.trainedmodel) %svm
        pred(:) = model.classfunc(model.trainedmodel, problem.testdata(:,model.features));
        res_se  = mean(sign(pred(problem.testlabels>0)) ==  1);
        res_sp  = mean(sign(pred(problem.testlabels<0)) == -1);
    elseif iscell(model.trainedmodel) %mlp
        for r = 1:nrep
            pred(:,r) = model.classfunc(model.trainedmodel{r}, problem.testdata(:,model.features));
            res_se(r) = mean(sign(pred(problem.testlabels>0,r)) ==  1);
            res_sp(r) = mean(sign(pred(problem.testlabels<0,r)) == -1);
        end
    end

    out = struct();
    out.se = mean(res_se);
    out.sp = mean(res_sp);
    out.gm = mean( geomean([res_se;res_sp]) );
    out.predict = mode(pred,2);

end
