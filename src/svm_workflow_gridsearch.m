function svm_workflow_gridsearch ( dataset, num_workers, iter )
    
    % save running data in dd structure
    dd = struct();
    dd.begintime = clock;
    dd.dataset = dataset;    
    dd.svm_kernel_func = 'rbf';
    %dd.svm_k_param_boxc = boxconstraint;
    %dd.svm_k_param_sigma = sigma;
    dd.num_pool_workers = num_workers;
    dd.num_iterations = iter;
    
    sigma = exp([-15:2:15]');
    boxconstraint = exp([-5:15]);
    best = 0;
    
    h = figure;
    while( dd.num_pool_workers > 1 )
        try
            matlabpool(dd.num_pool_workers);
            break
        catch e
            fprintf(['too many workers for system capacity. trying ' ...
                     'with %d..\n'],dd.num_pool_workers-1);
            dd.num_pool_workers=dd.num_pool_workers-1;
        end
    end
            
    for r=1:4
        
        % the following is for avoiding nested loops
        l_sigma = reshape( diag(sigma)*ones(length(sigma),length(boxconstraint)), 1, []);
        l_boxc  = reshape( ones(length(sigma),length(boxconstraint))*diag(boxconstraint), 1, []);

        perf_se = -ones( dd.num_iterations, length(l_boxc) ); % sensitivity
        perf_sp = -ones( dd.num_iterations, length(l_boxc) ); % specificity
        perf_an = -ones( dd.num_iterations, length(l_boxc) ); % almost-negative test result
    

        for t=1:iter

            fprintf('train/test iteration %d of %d..\n',t,dd.num_iterations);
            
            % fprintf( 'Loading test and train datasets... ' );
            [ train test ] = load_datasets(dd.dataset);
            % fprintf( 'done.\n' );
            fprintf( 'Training/testing with %d/%d entries.\n', ...
                     size(train,1), size(test,1) );
    
            % scale the data
            train_data = train(:,1:66);
            [train_data f s] = scale_data(train_data);
            test_data = scale_data(test(:,1:66),f,s);
    
            train_labels = train(:,67);
            test_labels  = test(:,67);

            parfor n=1:length(l_sigma)
            try
                lbls = train_labels;
                lbls(find(train_labels==0))=-1;
                model = svmtrain(train_data,lbls, ...
                                 'Kernel_Function','rbf', ...
                                 'rbf_sigma',l_sigma(n), ...
                                 'boxconstraint',l_boxc(n));

                res = round(svmclassify(model, test_data));
                
                pos  = find(    test_labels > 0.1);
                neg  = find(    test_labels <-0.1);
                aneg = find(abs(test_labels)< 0.1);
                
                perf_se(t,n) = 1-mean(abs(test_labels(pos)-res(pos)));
                perf_sp(t,n) = 1-mean(abs(test_labels(neg)-res(neg)));
                if length(aneg)>0
                    perf_an(t,n) = 1-mean(abs((test_labels(aneg)-1)-res(aneg)));
                else
                    perf_an(t,n) = mean([perf_se(t,n) perf_sp(t,n)]);
                end
            catch e
                %e
                % do nothing
            end  
            end
        end
        fprintf('done refining step %d\n',r);
    
        dd.test_perf = struct();
    
        perf_se(find(perf_se<0))=0;
        perf_sp(find(perf_sp<0))=0;
        perf_an(find(perf_an<0))=0;
        
        % display performance as a colored image
        dd.test_perf(r).training_errors  = reshape(mean(perf_se<0,1),length(sigma),[]);
        dd.test_perf(r).mean_sensitivity = reshape(mean(perf_se,1),length(sigma),[]);
        dd.test_perf(r).mean_specificity = reshape(mean(perf_sp,1),length(sigma),[]);
        dd.test_perf(r).mean_almost_neg  = reshape(mean(perf_an,1),length(sigma),[]);
        dd.test_perf(r).stdd_sensitivity = reshape( std(perf_se,0,1),length(sigma),[]);
        dd.test_perf(r).stdd_specificity = reshape( std(perf_sp,0,1),length(sigma),[]);
        dd.test_perf(r).stdd_almost_neg  = reshape( std(perf_an,0,1),length(sigma),[]);
    
        dd.test_perf(r).overall = reshape(mean([perf_se;perf_sp;perf_an],1), ...
                                          length(sigma),[]);
        
        mean_img = zeros( [size(dd.test_perf(r).mean_sensitivity) 3] );
        mean_img(:,:,1) = dd.test_perf(r).mean_sensitivity;
        mean_img(:,:,2) = dd.test_perf(r).mean_specificity;
        mean_img(:,:,3) = dd.test_perf(r).mean_almost_neg;

        subplot(2,2,r)
        image(mean_img);
        set(gca,'XTick',1:size(boxconstraint,2))
        set(gca,'YTick',1:size(sigma,1)')
        set(gca,'XTickLabel',boxconstraint)
        set(gca,'YTickLabel',sigma)
                
        best = max(max(dd.test_perf(r).overall));
        [bz, bc] = find(best-dd.test_perf(r).overall==0);

        sigma = exp([log(sigma(bz))-4/r:1/r:log(sigma(bz))+4/r])';
        boxconstraint = exp([log(boxconstraint(bc))-4/r:1/r:log(boxconstraint(bc))+4/r]);
    end
    matlabpool close;
        
    saveas(h, ['svmw-img-multiple-' datestr(dd.begintime) '.fig']);
    
    tt = round(etime(clock,dd.begintime));
    fprintf( 'Total script running time: %02d:%02d.\n', floor(tt/60), ...
             mod(tt,60))
    
    dd.running_time = tt;
    
    % save data to disk
    save( ['svmworkflow_rbf' datestr(dd.begintime) '.mat'],'-struct', 'dd');
end
