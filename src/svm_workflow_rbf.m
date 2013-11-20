function svm_workflow_rbf ( dataset, boxconstraint, sigma, num_workers, iter )
    
    % save running data in dd structure
    dd = struct();
    dd.begintime = clock;
    dd.dataset = dataset;    
    dd.svm_kernel_func = 'rbf';
    dd.svm_k_param_boxc = boxconstraint;
    dd.svm_k_param_sigma = sigma;
    dd.num_pool_workers = num_workers;
    dd.num_iterations = iter;
    
    % the following is for avoiding nested loops
    l_sigma = reshape( diag(sigma)*ones(length(sigma),length(boxconstraint)), 1, []);
    l_boxc  = reshape( ones(length(sigma),length(boxconstraint))*diag(boxconstraint), 1, []);

    perf_se = -ones( dd.num_iterations, length(l_boxc) ); % sensitivity
    perf_sp = -ones( dd.num_iterations, length(l_boxc) ); % specificity
    perf_an = -ones( dd.num_iterations, length(l_boxc) ); % almost-negative test result
    
    matlabpool(dd.num_pool_workers);

    for t=1:iter

        fprintf('train/test iteration %d of %d..\n',t,dd.num_iterations);

        fprintf( 'Loading test and train datasets... ' );
        [ train test ] = load_datasets(dd.dataset);
        fprintf( 'done.\n' );
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
                    perf_an(t,n) = rms([perf_se(t,n) perf_sp(t,n)]);
                end
            catch e
                %e
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

    % display performance as a colored image
    dd.test_perf.training_errors  = reshape(mean(perf_se<0,1),length(sigma),[]);
    dd.test_perf.mean_sensitivity = reshape(mean(perf_se,1),length(sigma),[]);
    dd.test_perf.mean_specificity = reshape(mean(perf_sp,1),length(sigma),[]);
    dd.test_perf.mean_almost_neg  = reshape(mean(perf_an,1),length(sigma),[]);
    dd.test_perf.stdd_sensitivity = reshape( std(perf_se,0,1),length(sigma),[]);
    dd.test_perf.stdd_specificity = reshape( std(perf_sp,0,1),length(sigma),[]);
    dd.test_perf.stdd_almost_neg  = reshape( std(perf_an,0,1),length(sigma),[]);
    
    mean_img = zeros( [size(dd.test_perf.mean_sensitivity) 3] );
    mean_img(:,:,1) = dd.test_perf.mean_sensitivity;
    mean_img(:,:,2) = dd.test_perf.mean_specificity;
    mean_img(:,:,3) = dd.test_perf.mean_almost_neg;
    
    %nor = sqrt( mean_img(:,:,1).^2 +  mean_img(:,:,2).^2 +  mean_img(:,:,3).^2 );
    h = figure;
    image(mean_img);
    set(gca,'XTick',1:size(boxconstraint,2))
    set(gca,'YTick',1:size(sigma,1)')
    set(gca,'XTickLabel',boxconstraint)
    set(gca,'YTickLabel',sigma)
    %surf(log10(C),log10(sigma), nor, mean_img)
    saveas(h, ['svmw-img-mean-' datestr(dd.begintime) '.fig']);
    
    stdd_img = zeros( [size(dd.test_perf.stdd_sensitivity) 3] );
    stdd_img(:,:,1) = dd.test_perf.stdd_sensitivity;
    stdd_img(:,:,2) = dd.test_perf.stdd_specificity;
    stdd_img(:,:,3) = dd.test_perf.stdd_almost_neg;
    
    h = figure;
    image(stdd_img);
    set(gca,'XTick',1:size(boxconstraint,2))
    set(gca,'YTick',1:size(sigma,1)')
    set(gca,'XTickLabel',boxconstraint)
    set(gca,'YTickLabel',sigma)
    saveas(h, ['svmw-img-stdd-' datestr(dd.begintime) '.fig']);    

    h = figure;
    subplot(2,2,1)
    imagesc(dd.test_perf.mean_sensitivity);
    colormap(gray)
    set(gca,'XTick',1:size(boxconstraint,2))
    set(gca,'YTick',1:size(sigma,1)')
    set(gca,'XTickLabel',boxconstraint)
    set(gca,'YTickLabel',sigma)
    subplot(2,2,2)
    imagesc(dd.test_perf.mean_specificity);
    colormap(gray)
    set(gca,'XTick',1:size(boxconstraint,2))
    set(gca,'YTick',1:size(sigma,1)')
    set(gca,'XTickLabel',boxconstraint)
    set(gca,'YTickLabel',sigma)
    subplot(2,2,3)
    imagesc(dd.test_perf.mean_almost_neg);
    colormap(gray)
    set(gca,'XTick',1:size(boxconstraint,2))
    set(gca,'YTick',1:size(sigma,1)')
    set(gca,'XTickLabel',boxconstraint)
    set(gca,'YTickLabel',sigma)
    subplot(2,2,4)
    imagesc(mean(stdd_img,3));
    colormap(gray)
    set(gca,'XTick',1:size(boxconstraint,2))
    set(gca,'YTick',1:size(sigma,1)')
    set(gca,'XTickLabel',boxconstraint)
    set(gca,'YTickLabel',sigma)
    %surf(log10(C),log10(sigma), nor, mean_img)
    saveas(h, ['svmw-img-multiple-' datestr(dd.begintime) '.fig']);
    
    
    tt = round(etime(clock,dd.begintime));
    fprintf( 'Total script running time: %02d:%02d.\n', floor(tt/60), ...
             mod(tt,60))
    
    dd.running_time = tt;
    
    % save data to disk
    save( ['svmworkflow_rbf' datestr(dd.begintime) '.mat'],'-struct', 'dd');
end
