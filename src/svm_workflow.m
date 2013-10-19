function [Z C perf] = svm_workflow ( )
    
    pick = @(x,n) x(randsample(size(x,1),min(size(x,1),n)),:);
    shuffle = @(x) x(randsample(size(x,1),size(x,1)),:);
        
    %% Xue's Triplet-SVM dataset

    POSITIVE_DATASETS = { 'mirbase50' };
    NEGATIVE_DATASETS = { 'coding' };
    POSITIVE_SPECIES  = { 'hsa' };
    NEGATIVE_SPECIES  = { '*' };
    TEST_DATASETS     = { 'updated' };
    TEST_SPECIES      = { '*' };
    
    pseudo = [];
    real   = [];
    test   = [];
    fprintf( 'Loading positive datasets:' );
    for j=1:length(POSITIVE_DATASETS)
        fprintf(' %s', POSITIVE_DATASETS{j});
        [d l] = load_dataset( POSITIVE_DATASETS{j}, POSITIVE_SPECIES);
        real = [real; d l];
    end
    fprintf( '\nLoading negative datasets:' );
    for j=1:length(NEGATIVE_DATASETS)
        fprintf(' %s', NEGATIVE_DATASETS{j});
        [d l] = load_dataset( NEGATIVE_DATASETS{j}, NEGATIVE_SPECIES);
        pseudo = [pseudo; d l];
    end
    fprintf( '\nLoading test datasets:' );
    for j=1:length(NEGATIVE_DATASETS)
        fprintf(' %s', TEST_DATASETS{j});
        [d l] = load_dataset( TEST_DATASETS{j}, TEST_SPECIES);
        test = [test; d l];
    end

    fprintf( '\nPositive dataset = %d entries, %d features\n', ...
             size(real,1), size(real,2)-1 );
    fprintf( 'Negative dataset = %d entries, %d features\n', ...
             size(pseudo,1), size(pseudo,2)-1 );
    fprintf( 'Test dataset = %d entries, %d features\n', ...
             size(test,1), size(test,2)-1 );
    
    % take 85% of smaller dataset, and (at most) double the other for training;
    % leave the rest for testing
    if size(real,1) < size(pseudo,1)
        n_real = round( size(real,1)*0.85 );
        n_pseudo = min( 2*n_real, size(pseudo,1) );
    else
        n_pseudo = round( size(pseudo,1)*0.85 );
        n_real = min( 2*n_pseudo, size(real,1) );
    end
    
    % generate the training set
    real = shuffle(real);
    pseudo = shuffle(pseudo);

    train = shuffle( [real(1:n_real,:); pseudo(1:n_pseudo,:)] );

    [train fac off] = scale_data(train);
    
    train_lbl = train(:,end); 
    train     = train(:,1:end-1);

    fprintf( 'Training with %d entries, %d positive samples and %d negative samples.\n', ...
             size(train,1), n_real, n_pseudo );

    % sigma parameter for the RBF kernel
    Z = [1e1 1e2 1e3 1e4 1e5 1e6 1e7 1e8];
    
    % boxconstraint parameter for the RBF kernel
    C = [1e-5 1e-4 1e-3 1e-2 1e-1 1 1e1 1e2 1e3 1e4 1e5 1e6 1e7 1e8 1e9 1e10];

    % scale the real, pseudo and test datasets
    real   = scale_data(real,   fac, off);
    pseudo = scale_data(pseudo, fac, off);
    test   = scale_data(test,   fac, off);
    
    test_real   =   real(  n_real+1:end,1:end-1);
    test_pseudo = pseudo(n_pseudo+1:end,1:end-1);

    test_real_lbl   =   real(  n_real+1:end,end);
    test_pseudo_lbl = pseudo(n_pseudo+1:end,end);

    test_lbl = test(:,end);
    test     = test(:,1:end-1);

    fprintf( 'After scaling, positive set labels average %8.6f, negative %8.6f.\n', ...
             mean(real(:,end)), mean(pseudo(:,end)));

    % here we save SE and SP for each Z-C combination
    perf = zeros( length(Z), length(C), 3 );
    
    matlabpool(2);
    for s=1:length(Z)
        for b=1:length(C)
            
            se = zeros(1,10);
            sp = zeros(1,10);
            te = zeros(1,10);

            try                                
            parfor t=1:10
                model = svmtrain(train,train_lbl,'Kernel_Function','rbf', ...
                                 'rbf_sigma',Z(s),'boxconstraint',C(b));
                
                se(t) = mean(abs(svmclassify(model, test_real)-test_real_lbl)< 0.5);
                sp(t) = mean(abs(svmclassify(model, test_pseudo)-test_pseudo_lbl)<0.5);
                te(t) = mean(abs(svmclassify(model, test)-test_lbl)<0.5);
                       
            end
                fprintf( 'sigma=%8.6g, boxcn=%8.6g, se=%-8.6f, sp=%-8.6f, up=%-8.6f\n', ...
                 Z(s), C(b), mean(se), mean(sp), mean(te) )
                
            catch e
                se = 0;
                sp = 0;
                te = 0;
            end
            perf(s,b,1) = mean(se);
            perf(s,b,2) = mean(sp);
            perf(s,b,3) = mean(te);
        end
    end
    matlabpool close;
    savefile('svmworkflow.mat','perf');
end
