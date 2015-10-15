function [Z C perf] = svm_workflow_xue ( )

    pick = @(x,n) x(randsample(size(x,1),min(size(x,1),n)),:);
    shuffle = @(x) x(randsample(size(x,1),size(x,1)),:);

    % save all running data in dd
    dd = struct();
    dd.begintime = clock;

    % xue dataset
    dset_xue = struct();
    dset_xue(1).name          = 'mirbase50';
    dset_xue(1).train_species = 'human';
    dset_xue(1).test_species  = 'human';
    dset_xue(1).train_ratio   = 163/193;
    dset_xue(1).test_ratio    = 30/193;

    dset_xue(2).name          = 'mirbase50';
    dset_xue(2).train_species = 'none';
    dset_xue(2).test_species  = 'non-human';
    dset_xue(2).train_ratio   = 0;
    dset_xue(2).test_ratio    = 1;

    dset_xue(3).name          = 'updated';
    dset_xue(3).train_species = 'none';
    dset_xue(3).test_species  = 'human';
    dset_xue(3).train_ratio   = 0;
    dset_xue(3).test_ratio    = 1;

    dset_xue(4).name          = 'coding';
    dset_xue(4).train_species = 'all';
    dset_xue(4).test_species  = 'all';
    dset_xue(4).train_ratio   = 168/8494;
    dset_xue(4).test_ratio    = 1000/8494;

    dset_xue(5).name          = 'conserved-hairpin';
    dset_xue(5).train_species = 'all';
    dset_xue(5).test_species  = 'all';
    dset_xue(5).train_ratio   = 0;
    dset_xue(5).test_ratio    = 1; % long =2444


    % ng dataset
    dset_ng = struct();
    dset_ng(1).name          = 'mirbase82'; % TR-H, TE-H
    dset_ng(1).train_species = 'human';
    dset_ng(1).test_species  = 'all';
    dset_ng(1).train_ratio   = 200/323;
    dset_ng(1).test_ratio    = 123/323;

    dset_ng(2).name          = 'coding'; % TR-H, TE-H
    dset_ng(2).train_species = 'all';
    dset_ng(2).test_species  = 'all';
    dset_ng(2).train_ratio   = 400/8494;
    dset_ng(2).test_ratio    = 236/8494;

    dset_ng(3).name          = 'mirbase82'; % IE-NH
    dset_ng(3).train_species = 'none';
    dset_ng(3).test_species  = 'non-human';
    dset_ng(3).train_ratio   = 0;
    dset_ng(3).test_ratio    = 1;

    dset_ng(4).name          = 'functional-ncrna'; % IE-NC
    dset_ng(4).train_species = 'none';
    dset_ng(4).test_species  = 'all';
    dset_ng(4).train_ratio   = 0;
    dset_ng(4).test_ratio    = 1; % long = 2657 (originally 12387)

    % IE-M dataset from NG not included (as they're all multi loop)

    % batuwita dataset
    dset_btw = struct();
    dset_btw(1).name          = 'mirbase12-nr'; %
    dset_btw(1).train_species = 'human';
    dset_btw(1).test_species  = 'none';
    dset_btw(1).train_ratio   = 1; % 660 entries (original=691)
    dset_btw(1).test_ratio    = 0;

    dset_btw(2).name          = 'coding'; %
    dset_btw(2).train_species = 'all';
    dset_btw(2).test_species  = 'none';
    dset_btw(2).train_ratio   = 1;
    dset_btw(2).test_ratio    = 0;

    dset_btw(3).name          = 'other-ncrna'; % human other ncrna
    dset_btw(3).train_species = 'all';
    dset_btw(3).test_species  = 'none';
    dset_btw(3).train_ratio   = 1; % 129 entries (original=754)
    dset_btw(3).test_ratio    = 0;


    dd.dataset = dset_xue;

    fprintf( 'Loading test and train datasets.. ' );
    [ train test ] = load_datasets(dd.dataset);
    fprintf( 'done.\n' );

    dd.train_ids = train(:,67:70);
    dd.test_ids  = test(:,67:70);


    % scale the data
    train_data = train(:,1:66);
    [train_data f s] = scale_data(train_data);
    test_data = scale_data(test(:,1:66),f,s);

    train_labels = train(:,67);
    test_labels  = test(:,67);

    fprintf( 'Training with %d entries.\n', size(train,1) );
    fprintf( 'Testing  with %d entries.\n', size(test,1) );

    dd.norm_factor = f;
    dd.norm_shift  = s;

    dd.svm_kernel_func = 'rbf';

    % sigma parameter for the RBF kernel
    Z = [1e-3 1e-2 1e-1 1e0 1e1 1e2 1e3 1e4 1e5 1e6 1e7 1e8 1e9 1e10 1e11 1e12 1e13]';

    % boxconstraint parameter for the RBF kernel
    C = [1e-5 1e-4 1e-3 1e-2 1e-1 1 1e1 1e2 1e3 1e4 1e5 1e6 1e7 1e8 ...
         1e9 1e10 1e11 1e12 1e13 1e14 1e15 1e16];

    dd.svm_k_param_sigma = Z;
    dd.svm_k_param_boxc  = C;

    dd.num_pool_workers = 2;
    dd.num_repeats = 1;

    % the following is for avoiding nested loops
    l_sigma = reshape( diag(Z)*ones(length(Z),length(C)), 1, []);
    l_boxc  = reshape( ones(length(Z),length(C))*diag(C), 1, []);

    perf_se = -ones( dd.num_repeats, length(Z)*length(C) ); % sensitivity
    perf_sp = -ones( dd.num_repeats, length(Z)*length(C) ); % specificity
    perf_an = -ones( dd.num_repeats, length(Z)*length(C) ); % almost-negative test result

    matlabpool(dd.num_pool_workers);

    for t=1:dd.num_repeats
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
    % dd.test_perf.mean_sensitivity = exp(2*reshape(mean(perf_se,1),length(Z),[]))/(exp(1)^2);
    % dd.test_perf.mean_specificity = exp(2*reshape(mean(perf_sp,1),length(Z),[]))/(exp(1)^2);
    % dd.test_perf.mean_almost_neg  = exp(2*reshape(mean(perf_an,1),length(Z),[]))/(exp(1)^2);
    dd.test_perf.mean_sensitivity = reshape(mean(perf_se,1),length(Z),[]);
    dd.test_perf.mean_specificity = reshape(mean(perf_sp,1),length(Z),[]);
    dd.test_perf.mean_almost_neg  = reshape(mean(perf_an,1),length(Z),[]);
    dd.test_perf.stdd_sensitivity = reshape( std(perf_se,0,1),length(Z),[]);
    dd.test_perf.stdd_specificity = reshape( std(perf_sp,0,1),length(Z),[]);
    dd.test_perf.stdd_almost_neg  = reshape( std(perf_an,0,1),length(Z),[]);

    %[gZ gC] = meshgrid(Z,C);

    mean_img = zeros( [size(dd.test_perf.mean_sensitivity) 3] );
    mean_img(:,:,1) = dd.test_perf.mean_sensitivity+dd.test_perf.training_errors;
    mean_img(:,:,2) = dd.test_perf.mean_specificity+dd.test_perf.training_errors;
    mean_img(:,:,3) = dd.test_perf.mean_almost_neg+dd.test_perf.training_errors;


    image(log10(C),log10(Z),mean_img);

    % tt = etime(clock,dd.begintime);
    % fprintf( 'Total script running time: %2d:%2d.\n', floor(tt/60), ...
    %          mod(tt,60))

    % dd.results = perf;
    % dd.running_time = tt;

    % % save data
    % save( ['svmworkflow' datestr(begintime) '.mat'],'-struct', 'dd');
end
