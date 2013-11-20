function svm_xue ( )
        
    % load train datasets
    real = loadset('mirbase50','human');
    pseudo = loadset('coding','all');
   
    [tr_real ts_real] = partset(real, 163);
    [ts_pseudo tr_pseudo] = partset(pseudo,832,1000);
    % CATCH: el training set pseudo es totalmente diferente
    % en cada iteración
    
    % test datasets
    cross_sp = loadset('mirbase50','non-human');
    conserved = loadset('conserved-hairpin','all');
    updated = loadset('updated','human');
    

    % SVM training and crossval
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

    
    
    
    %svm_workflow_gridsearch (dataset, N, I)

    
    
    
end
