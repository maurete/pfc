function [svm_params paramh errh] = select_model_empirical(dataset, featset, kernel, lib, ...
                                                      theta0, npart, ratio, randseed, data)

    if nargin < 9 || isempty(data),         data = false; end
    if nargin < 8 || isempty(randseed), randseed = 1135; end
    if nargin < 7 || isempty(ratio),       ratio = 0; end
    if nargin < 6 || isempty(npart),       npart = 5; end

    % MISC SETTINGS
    gtol = 1e-6 * 2;
    exponential = false;
    stop_delta = 0.001;
    method = 'rprop';

    com = common;

    % find out if rbf kernel is selected
    % find out if which kernel is selected
    if     strncmpi(kernel,'rbf_uni',7);    kernel = 'rbf_uni';
    elseif strncmpi(kernel,'rbf_unc',7);    kernel = 'rbf_unc';
    elseif strncmpi(kernel,'linear_uni',10); kernel = 'linear_uni';
    elseif strncmpi(kernel,'linear_unc',10); kernel = 'linear_unc';
    elseif strncmpi(kernel,'lin',3);        kernel = 'linear';
    elseif strncmpi(kernel,'rbf',4);        kernel = 'rbf';
    else error('! fatal error: unknown kernel function specified.');
    end

    features = com.featindex{featset};

    %%% Load data %%%

    if ~isstruct(data)
        data = struct();
        [data.train data.test] = load_data(dataset, randseed, false);
    end
    % generate CV partitions
    traindata = com.stshuffle(randseed,[data.train.real; data.train.pseudo]);
    [part.train part.validation] = stpart(randseed, traindata, npart, ratio);

    target = traindata(:,67);
    input = traindata(:,features);

    % initial parameter vector
    if nargin > 4 && ~isempty(theta0), theta = theta0;
    elseif strfind(kernel,'rbf') theta = [0 0];
    else theta = 0;
    end
    
    if exponential, tf = @exp; else tf = @(t) t; end

    trainfunc = @(input,target,theta) ...
        model_csvm_train(lib, kernel, input, target, theta(1), theta(2:end), false, 1e-6);
        testfunc = @(model, inputs) model_csvm(model, inputs, true, exponential);
        testfunc_deriv = @(model, inputs) model_csvm_deriv(model, inputs, true, exponential);

    if strcmp(method,'bfgs')
        err_func = @(theta) error_empirical_csvm(trainfunc, testfunc, [], tf(theta), part, ...
                                             input, target);
        [svm_params,~,paramh,errh] = opt_bfgs_simple( err_func, false, theta, 1e-6, 100 )
    
    else
    
        svm_params = theta;
        err = inf;
        errh = [ err ];
        paramh = [svm_params];
    
        err_func = @(model,deriv,args,input,target) error_empirical_csvm(trainfunc, model, ...
                                                          deriv, tf(args), part, ...
                                                          input, target);
        
        rprop = opt_rpropplus(svm_params);
        for i=1:100
            [svm_params, err] = rprop.optimize( testfunc, testfunc_deriv, svm_params, ...
                                                err_func, [], input, target );
            paramh(end+1,:) = svm_params;
            errh(end+1,:) = err;
            if ~exponential, svm_params(svm_params<=0) = 1e-5; end
            if strncmp(kernel, 'rbf', 3)
                fprintf('svm C=%8.3f g=%8.3f err=%8.3f, delta=%8.3f, %8.3f\n', ...
                        svm_params(1), svm_params(2), err, rprop.delta(1), rprop.delta(2))
            elseif strncmp(kernel, 'lin', 3)
                fprintf('svm C=%8.3f err=%8.3f, delta=%8.3f\n', ...
                        svm_params(1), err, rprop.delta(1))
            end
            if rprop.maxdelta() < stop_delta, break, end
        end
        
        % unconstrained = false;
        % if strcmp(kernel, 'rbf_unc'), unconstrained = true, end
        % if strcmp(kernel, 'linear_unc'), kernel = 'linear'; unconstrained = true, end

        % trainfunc = @(trainset, trainlbl, args) ...
        %     model_csvm_train(lib, kernel, trainset, trainlbl, args(1), args(2:end), false, 1e-6, false, unconstrained);
        % testfunc = @(model, inputs) model_csvm(model, inputs, true, unconstrained);
        % testfunc_deriv = @(model, inputs) model_csvm_deriv(model, inputs, true, unconstrained);
        % errfunc = @(model,deriv,args,input,target)...
        %           error_empirical_csvm(trainfunc,model,deriv,args,part,input,target);
    end
    

    %%% test best-performing parameters %%%

    res = com.run_tests(data,featset,randseed,kernel,lib,tf(svm_params(1)),tf(svm_params(2:end)) );
    com.print_test_info(res);
    
end