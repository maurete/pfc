function out = problem_test(problem, varargin)

    % perform tests on problem test datasets

    p = struct();
    p.mlp = false;
    p.svm = false;

    pmlp = {'lib', 'hiddensizes', 'method', 'repeat'};
    psvm = {'lib', 'kernel', 'C', 'kparam', 'tol'};

    if strcmpi(varargin{1},'mlp'), p.mlp = true;
    else p.svm = true;
    end

    for pi = 2:nargin
        if p.mlp, p.(pmlp{pi-1}) = varargin{pi-1};
        elseif p.svm, p.(psvm{pi-1}) = varargin{pi-1};
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

    nrep   = p.repeat;
    ntests = length(problem(1).test);

    sen_source = [];
    spe_source = [];
    sen_other  = [];
    spe_other  = [];

    res_test = zeros(ntests,nrep);
    features = problem.featindex;

    if p.mlp
        trainfunc = @(in,tg) mlp_train(in,tg,p.hiddensizes,p.method);
        testfunc  = @mlp_classify;
    elseif p.svm
        trainfunc = @(in,tg) mysvm_train( ...
            p.lib, p.kernel, problem.trainset, problem.trainlabels, ...
            p.C, p.kparam, false, p.tol );
        testfunc  = @mysvm_classify;
    end

    try
        for r = 1:nrep
            model = trainfunc(problem.trainset, problem.trainlabels);
            for i=1:ntests
                [cls_results] = testfunc(model, problem(1).test(i).data(:,features));
                res_test(i,r)   = mean(sign(cls_results) == problem(1).test(i).class);
                if problem(1).test(i).class == 1
                    if problem(1).test(i).trained, sen_source(end+1) = res_test(i,r);
                    else sen_other(end+1) = res_test(i,r); end
                elseif problem(1).test(i).class == -1
                    if problem(1).test(i).trained, spe_source(end+1) = res_test(i,r);
                    else spe_other(end+1) = res_test(i,r); end
                end
            end
        end
    catch e, warning('%s: %s', e.identifier, e.message)
    end % try

    out = struct();
    out.sen_source = mean(sen_source);
    out.spe_source = mean(spe_source);
    out.sen_other  = mean(sen_other);
    out.spe_other  = mean(spe_other);
    for i=1:ntests
        out(i).name  = problem(1).test(i).name;
        out(i).class = problem(1).test(i).class;
        out(i).size  = size(problem(1).test(i).data,1);
        out(i).rate  = mean(res_test(i,:));
    end
end
