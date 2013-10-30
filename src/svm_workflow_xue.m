function svm_workflow_xue ( )
    
    % save all running data in dd structure
    dd = struct();
    dd.begintime = clock;
    
    % xue dataset
    dd.dataset = struct();
    dd.dataset(1).name          = 'mirbase50';
    dd.dataset(1).train_species = 'human';
    dd.dataset(1).test_species  = 'human';
    dd.dataset(1).train_ratio   = 163/193;
    dd.dataset(1).test_ratio    = 30/193;
    
    dd.dataset(2).name          = 'mirbase50';
    dd.dataset(2).train_species = 'none';
    dd.dataset(2).test_species  = 'non-human';
    dd.dataset(2).train_ratio   = 0;
    dd.dataset(2).test_ratio    = 1;

    dd.dataset(3).name          = 'updated';
    dd.dataset(3).train_species = 'none';
    dd.dataset(3).test_species  = 'human';
    dd.dataset(3).train_ratio   = 0;
    dd.dataset(3).test_ratio    = 1;

    dd.dataset(4).name          = 'coding';
    dd.dataset(4).train_species = 'all';
    dd.dataset(4).test_species  = 'all';
    dd.dataset(4).train_ratio   = 168/8494;
    dd.dataset(4).test_ratio    = 1000/8494;

    dd.dataset(5).name          = 'conserved-hairpin';
    dd.dataset(5).train_species = 'all';
    dd.dataset(5).test_species  = 'all';
    dd.dataset(5).train_ratio   = 0;
    dd.dataset(5).test_ratio    = 1; % long =2444

    %dd.norm_factor = f;
    %dd.norm_shift  = s;
    
    dd.svm_kernel_func = 'rbf';
    
    % sigma parameter for the RBF kernel
    Z = [1e0 10^0.5 10^0.9 10^0.95 1e1 10^1.05 10^1.1 10^1.15 10^1.2 10^1.5 1e2 10^2.5 1e3 1e4 1e5 1e6 1e7 1e8 1e9]';
    
    % boxconstraint parameter for the RBF kernel
    C = [1e-3 1e-2 1e-1 10^-0.5 1e0 10^0.5 1e1 10^1.5 10^1.75 1e2 10^2.25 10^2.5 1e3 1e4 1e5 1e6 1e7 1e8];

    dd.svm_k_param_sigma = Z;
    dd.svm_k_param_boxc  = C;
    
    dd.num_pool_workers = 12;
    dd.num_repeats = 10;
    
    % the following is for avoiding nested loops
    l_sigma = reshape( diag(Z)*ones(length(Z),length(C)), 1, []);
    l_boxc  = reshape( ones(length(Z),length(C))*diag(C), 1, []);

    perf_se = -ones( dd.num_repeats, length(Z)*length(C) ); % sensitivity
    perf_sp = -ones( dd.num_repeats, length(Z)*length(C) ); % specificity
    perf_an = -ones( dd.num_repeats, length(Z)*length(C) ); % almost-negative test result
    
    matlabpool(dd.num_pool_workers);

    for t=1:dd.num_repeats


    fprintf( 'Loading test and train datasets... ' );
    [ train test ] = load_datasets(dd.dataset);
    fprintf( 'done.\n' );
    fprintf( 'Training/testing with %d/%d entries.\n', ...
	     size(train,1), size(test,1) );
    
    dd.train_ids = train(:,67:70);
    dd.test_ids  = test(:,67:70);
    
    % scale the data
    train_data = train(:,1:66);
    [train_data f s] = scale_data(train_data);
    test_data = scale_data(test(:,1:66),f,s);
    
    train_labels = train(:,67); 
    test_labels  = test(:,67);



        fprintf('training repeat %d out of %d..\n',t,dd.num_repeats);
        parfor n=1:length(l_sigma)
            try
                model = svmtrain(train_data,train_labels, ...
                                 'Kernel_Function','rbf', ...
                                 'rbf_sigma',l_sigma(n), ...
                                 'boxconstraint',l_boxc(n));

                res = round(svmclassify(model, test_data));
                
                pos  = find(    test_labels > 0.1);
                neg  = find(    test_labels <-0.1);
                aneg = find(abs(test_labels)< 0.1);
                
                perf_se(t,n) = 1-mean(abs(test_labels(pos)-res(pos)));
                perf_sp(t,n) = 1-mean(abs(test_labels(neg)-res(neg)));
                perf_an(t,n) = 1-mean(abs((test_labels(aneg)-1)-res(aneg)));
                
            catch e
                % do nothing
            end  
        end
    end
    matlabpool close;
    
    fprintf('done!\n');
    
    dd.test_perf = struct();
    
    perf_se(find(perf_se<0))=0;
    perf_sp(find(perf_sp<0))=0;
    perf_an(find(perf_an<0))=0;
    
    dd.test_perf.training_errors  = reshape(mean(perf_se<0,1),length(Z),[]);
    dd.test_perf.mean_sensitivity = reshape(mean(perf_se,1),length(Z),[]);
    dd.test_perf.mean_specificity = reshape(mean(perf_sp,1),length(Z),[]);
    dd.test_perf.mean_almost_neg  = reshape(mean(perf_an,1),length(Z),[]);
    dd.test_perf.stdd_sensitivity = reshape( std(perf_se,0,1),length(Z),[]);
    dd.test_perf.stdd_specificity = reshape( std(perf_sp,0,1),length(Z),[]);
    dd.test_perf.stdd_almost_neg  = reshape( std(perf_an,0,1),length(Z),[]);
    
    mean_img = zeros( [size(dd.test_perf.mean_sensitivity) 3] );
    mean_img(:,:,1) = dd.test_perf.mean_sensitivity;
    mean_img(:,:,2) = dd.test_perf.mean_specificity;
    mean_img(:,:,3) = dd.test_perf.mean_almost_neg;
    
    nor = sqrt( mean_img(:,:,1).^2 +  mean_img(:,:,2).^2 +  mean_img(:,:,3).^2 );

    h = figure;
    surf(log10(C),log10(Z), nor, mean_img)
    %image(log10(C),log10(Z),mean_img);
    saveas(h, ['svmw-img-mean-' datestr(dd.begintime) '.fig']);
    
    stdd_img = zeros( [size(dd.test_perf.stdd_sensitivity) 3] );
    stdd_img(:,:,1) = dd.test_perf.stdd_sensitivity;
    stdd_img(:,:,2) = dd.test_perf.stdd_specificity;
    stdd_img(:,:,3) = dd.test_perf.stdd_almost_neg;
    
    h = figure;
    image(log10(C),log10(Z),stdd_img);
    saveas(h, ['svmw-img-stdd-' datestr(dd.begintime) '.fig']);

    tt = round(etime(clock,dd.begintime));
    fprintf( 'Total script running time: %02d:%02d.\n', floor(tt/60), ...
             mod(tt,60))
    
    dd.running_time = tt;
    
    % save data
    save( ['svmworkflow' datestr(dd.begintime) '.mat'],'-struct', 'dd');
end
