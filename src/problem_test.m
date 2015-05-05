function out = problem_test(problem, feats, varargin)

    % perform tests on problem test datasets
    p = struct();
    p.mlp = false;
    p.svm = false;
    p.fann = false;

    pmlp = {'lib', 'hiddensizes', 'method', 'repeat'};
    psvm = {'lib', 'kernel', 'C', 'kparam', 'tol'};

    if strcmpi(varargin{1},'mlp'), p.mlp = true;
    elseif strcmpi(varargin{1},'fann'), p.fann = true; p.mlp = true;
    else p.svm = true;
    end

    for pi = 1:nargin-2
        if p.mlp, p.(pmlp{pi}) = varargin{pi};
        elseif p.svm, p.(psvm{pi}) = varargin{pi};
        end
    end

    if p.mlp
        if ~isfield(p,'repeat'), p.repeat = 5; end
        if ~isfield(p,'method'), p.method = 'trainrp'; end
        if ~isfield(p,'hiddensizes'), p.hiddensizes = []; end
    elseif p.svm
        if ~isfield(p,'repeat'), p.repeat = 1; end
        if ~isfield(p,'tol'), p.tol = 1e-6; end
        if ~isfield(p,'kparam'), p.kparam = []; end
        if ~isfield(p,'C'), error('C-parameter not specified'); end
    end

    if p.mlp
        trainfunc = @(in,tg) mlp_xtrain(in,tg,[],[],p.hiddensizes,p.method,[],p.fann);
        testfunc  = @mlp_classify;
    elseif p.svm
        trainfunc = @(in,tg) mysvm_train( ...
            p.lib, p.kernel, in, tg, ...
            p.C, p.kparam, false, p.tol );
        testfunc  = @mysvm_classify;
    end

    nrep   = p.repeat;
    res_se = nan(1,nrep);
    res_sp = nan(1,nrep);
    pred   = nan(numel(problem.testlabels),nrep);

    features = featset_index(feats);
    try
        %model = struct();
        for r = 1:nrep
            model(r)  = trainfunc(problem.traindata(:,features), problem.trainlabels);
            pred(:,r) = testfunc(model(r), problem.testdata(:,features));
            res_se(r) = mean(sign(pred(problem.testlabels>0,r)) ==  1);
            res_sp(r) = mean(sign(pred(problem.testlabels<0,r)) == -1);
        end
    catch e, warning('%s: %s', e.identifier, e.message)
    end % try

    out = struct();
    out.se = mean(res_se);
    out.sp = mean(res_sp);
    out.gm = mean( geomean([res_se;res_sp]) );
    out.model = model;
    out.predict = mode(pred,2);

end
