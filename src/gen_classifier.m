function gen_classifier( type, params, data, features, out, seed)
% generates classifier of type _type_, with parameters _params_,
% trained with data _data_, using features _features_, and saves
% it to a filename named _out_
%
% for svm_rbf, params should be [sigma, boxconstraint]
% for svm_linear, params should be [boxconstraint]
% for mlp, params should be [number of neurons in hidden layer]
%

    if nargin < 6
        seed = 438957;
    end
    
    stpick    = @(x,n) x(strandsample(seed,size(x,1),min(size(x,1),n)),:);
    stshuffle = @(x)   x(strandsample(seed,size(x,1),size(x,1)),:);

    fidx = { 1:66; 1:32; 33:36; 37:59; 60:66; 1:36; [1:36 60:66]; ...
             37:66; 1:59; 33:66; [33:36 60:66]; 33:59; [1:32 60:66]; ...
             [1:32 37:59]; [1:32 37:66] };
    fset = fidx{features};

    train = [];
    test = [];
    model = [];
    
    if strncmpi(type, 'svm', 3)

        [train test] = load_data( data, seed );
        train_data = stshuffle( [ train.real; train.pseudo ] );
        
        %train
        fprintf('#\n# training...\n');
        if strcmpi(type,'svm_rbf') | strcmpi(type,'svm-rbf')
            model = svmtrain(train_data(:,fset),train_data(:,67), ...
                             'Kernel_Function','rbf', ...
                             'rbf_sigma',params(1), ...
                             'boxconstraint',params(2));
        elseif strncmpi(type,'svm_linear',7) | strncmpi(type,'svm-linear',7)
            model = svmtrain(train_data(:,fset),train_data(:,67), ...
                             'Kernel_Function','linear', ...
                             'boxconstraint',params);
        end
        
        % test
        fprintf('#\n# test results:\n');
        fprintf('# \t\tdataset\t\t\tclass\tsize\tperformance\n');
        fprintf('# \t\t-------\t\t\t-----\t----\t-----------\n');
        for i=1:length(test)
            res = round(svmclassify(model, test(i).data(:,fset)));
            perf = mean( res == test(i).class);
            fprintf('+ %32s\t%d\t%d\t%8.6f\n',...
                    test(i).name, test(i).class, size(test(i).data,1), perf);
        end
    
    elseif strcmpi(type,'mlp')

        [train test] = load_data( data, seed, true);
        train_data = stshuffle( [ train.real; train.pseudo ] );

        %train
        fprintf('#\n# training...\n');
        model = patternnet( params );
                    
        model.trainFcn = 'trainscg';
        model.trainParam.showWindow = 0;
        model.trainParam.time = 10;
        model.trainParam.epochs = 2000000000000;
                
        model = init(model);
        model = train(model, train_data(:,fset)', train_data(:,67)');

        %test
        fprintf('#\n# test results:\n');
        fprintf('# \t\tdataset\t\t\tclass\tsize\tperformance\n');
        fprintf('# \t\t-------\t\t\t-----\t----\t-----------\n');

        for i=1:length(test)
            res = round(svmclassify(model, test(i).data(:,fset)));
            perf = mean( res == test(i).class);
            fprintf('+ %32s\t%d\t%d\t%8.6f\n',...
                    test(i).name, test(i).class, size(test(i).data,1), perf);
        end
        
    else
        fprintf('Unknown classifier type. should be one of svm_(linear|rbf) or mlp.')
        return
    end
    
    % save output file
    save(out, model, params, features, seed, '-ascii')
        
        
endfunction