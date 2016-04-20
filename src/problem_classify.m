function out = problem_classify(problem, model)
%PROBLEM_CLASSIFY Classify test datasets on PROBLEM with MODEL
%
%  OUT = PROBLEM_CLASSIFY(PROBLEM,MODEL) Performs classification of the test
%  dataset present in PROBLEM by running the classification function in MODEL.
%  PROBLEM is a problem as returned by PROBLEM_GEN, and MODEL is a model struct
%  as returned by any of the SELECT_MODEL* functions. OUT is a structure with
%  fields:
%      .se:      sensitivity (valid only when test labels are supplied)
%      .sp:      specificity (valid only when test labels are supplied)
%      .gm:      sqrt(se*sp) (valid only when test labels are supplied)
%      .predict: class prediction elements in the 'testdata' field of PROBLEM.
%
%  See also PROBLEM_GEN, SELECT_MODEL.
%

    % if MLP model, classify with all trained networks in model
    nrep = 1;
    if iscell(model.trainedmodel), nrep = numel(model.trainedmodel); end

    % predictions
    pred = nan(numel(problem.testlabels),nrep);

    % classification function
    clsfunc = model.classfunc;
    if isstr(model.classfunc), clsfunc = str2func(model.classfunc); end

    % perform classification on the test dataset
    if isstruct(model.trainedmodel)

        % SVM case
        pred(:) = clsfunc(model.trainedmodel, ...
                          problem.testdata(:,model.features));

    elseif iscell(model.trainedmodel)

        % MLP case: repeat <nrep> times
        for r = 1:nrep
            pred(:,r) = clsfunc(model.trainedmodel{r}, ...
                                problem.testdata(:,model.features));
        end

        % set most voted class prediction
        pred = mode(pred,2);

    end

    % output structure
    out = struct();
    out.predict = pred;
    out.se = mean(sign(pred(problem.testlabels>0)) ==  1);
    out.sp = mean(sign(pred(problem.testlabels<0)) == -1);
    out.gm = geomean([out.se; out.sp]);

end
