function svm_xue_new ( num_iterations )
        
    if nargin < 1
        num_iterations = 10
    end
    
    % load train datasets
    real = loadset('mirbase50','human', 0);
    pseudo = loadset('coding','all', 1);
       
    % test datasets
    cross_sp = loadset('mirbase50','non-human', 2);
    conserved = loadset('conserved-hairpin','all', 3);
    updated = loadset('updated','human', 4);
    
    num_workers = 12;

    if matlabpool('size') == 0
        while( num_workers > 1 )
            try
                matlabpool(num_workers);
                break
            catch e
                num_workers = num_workers-1;
                fprintf(['too many workers, trying with %d..\n'], num_workers);
            end
        end
    end
    
    shuffle = @(x) x(randsample(size(x,1),size(x,1)),:);
    
    featset = [ 1 32; 33 36; 37 59; 60 66; 1 66 ];
    
    sigma = exp([-15:2:15]');
    boxconstraint = exp([-5:2:15]);
    l_sigma = reshape( diag(sigma)*ones(length(sigma),length(boxconstraint)), 1, []);
    l_boxc  = reshape( ones(length(sigma),length(boxconstraint))*diag(boxconstraint), 1, []);
    
    paramset = zeros( length(l_sigma), 2, 5);
    paramset(:,:,1)=[ l_sigma', l_boxc' ];
    paramset(:,:,2)=[ l_sigma', l_boxc' ];
    paramset(:,:,3)=[ l_sigma', l_boxc' ];
    paramset(:,:,4)=[ l_sigma', l_boxc' ];
    paramset(:,:,5)=[ l_sigma', l_boxc' ];
    
    keep = zeros(size(paramset,1),5);
    skip = zeros(size(paramset,1),5);
    
    % parameter refining
    for r = [ 1 0.5 0.2 0.1 0.05 ]
        
        se = zeros( num_iterations, size(paramset,1), 5 ); % sensitivity
        sp = zeros( num_iterations, size(paramset,1), 5 ); % specificity

        % SVM training and crossval
        [tr_real ts_real] = partset(real, 163);
        [ts_pseudo tr_pseudo] = partset(pseudo,1000,1168);
        % VER: el training set pseudo es totalmente diferente
        % en cada iteración
        % if f == 1
        %     fprintf('REAL %d PSEUDO %d TR+ %d TR- %d TE+ %d TE- %d\n', ...
        %             size(real,1), size(pseudo,1), size(tr_real,1), ...
        %             size(tr_pseudo,1), size(ts_real,1), size(ts_pseudo, 1))
        % end
            
        ir = 1;
        ip = 1;
        for t=1:num_iterations
            % regenerate partitions 
            if ir > size(tr_real,2)
                [tr_real ts_real] = partset(real,163); ir=1;
            end
            if ip > size(tr_pseudo,2)
                [ts_pseudo tr_pseudo] = partset(pseudo,832,1000); ip=1;
            end

            train_data = shuffle( [  real(  tr_real(:,ir),1:67); ...
                                pseudo(tr_pseudo(:,ip),1:67)] );
            train_lbls = train_data(:,67);
            [train_data f s] = scale_data(train_data(:,1:66));

            test_real   = scale_data(  real(  ts_real(:,ir),1:66),f,s);
            test_pseudo = scale_data(pseudo(ts_pseudo(:,ip),1:66),f,s);
          
            % train with different feature sets
            for fs = 1:5
                parfor n=1:size(paramset,1)
                    if skip(n,fs) continue; end
                    try
                        model = svmtrain(train_data(:,featset(fs,1):featset(fs,2)),train_lbls, ...
                                         'Kernel_Function','rbf', ...
                                         'rbf_sigma',paramset(n,1), ...
                                         'boxconstraint',paramset(n,2));

                        res_r = round(svmclassify(model, test_real(:,featset(fs,1):featset(fs,2))));
                        res_p = round(svmclassify(model, test_pseudo(:,featset(fs,1):featset(fs,2))));
                
                        se(t,n,fs) = mean( res_r == 1 );
                        sp(t,n,fs) = mean( res_p == -1 );

                        if geomean( [se(t,n,fs) sp(t,n,fs)] ) < 0.3
                            skip(n,fs) = 1;
                        end
                  
                    catch e
                        skip(n,fs) = 1;
                    end  
                end
            end
        end
        
        avg_se = mean(se,1);
        avg_sp = mean(sp,1);
        avg_gm = geomean([avg_se;avg_sp],1);
        best = max(avg_gm,[],2);
        
        for i = 1:5
            keep( find( best(1,1,i)-avg_gm(:,:,i) == 0 ), i ) = 1; 
        end
        
        for i = 1:5
            idx = find(keep(:,i));
            for j=1:length(idx)
                fprintf('fset %d best: SE %8.6f SP %8.6f GM %8.6f for Z,C %8.6f %8.6f\n', ...
                        i, avg_se(1,idx(j),i),avg_sp(1,idx(j),i),avg_gm(1,idx(j),i),...
                        paramset(idx(j),1), paramset(idx(j),2) );
            end
        end
        
        
        
        break

      sigma = exp([log(sigma(bz))-4/r:1/r:log(sigma(bz))+4/r])';
      boxconstraint = exp([log(boxconstraint(bc))-4/r:1/r:log(boxconstraint(bc))+4/r]);

    end
    matlabpool close
end
