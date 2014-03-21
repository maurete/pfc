function [ out ] = rbf_gridsearch ( params, train )

    % aux functions
    pick      = @(x,n) x(randsample(size(x,1),min(size(x,1),n)),:);
    shuffle   = @(x)   x(randsample(size(x,1),size(x,1)),:);
    stpick    = @(x,n) x(strandsample(rec.random_seed,size(x,1),min(size(x,1),n)),:);
    stshuffle = @(x)   x(strandsample(rec.random_seed,size(x,1),size(x,1)),:);
    function o=zerofill(i),o=0;if i,o=i;end,end

    % generate cross-validation partitions
    [tr_real ts_real]     = stpart(params.random_seed, train.real, params.num_partitions);
    [tr_pseudo ts_pseudo] = stpart(params.random_seed, train.pseudo, params.num_partitions);
    
    fprintf('REAL %d PSEUDO %d TR+ %d TR- %d TE+ %d TE- %d\n', ...
            size(train.real,1), size(train.pseudo,1), size(tr_real,1), ...
            size(tr_pseudo,1), size(ts_real,1), size(ts_pseudo, 1))
    
    % create matlab pool
    num_workers = 12;
    if matlabpool('size') == 0
        while( num_workers > 1 )
            try
                matlabpool(num_workers);
                break
            catch e
                num_workers = num_workers-1;
                fprintf(['trying %d workers..\n'], num_workers);
            end
        end
    end


    begintime = clock;
    time = 0;
    numcv = 0;
    fprintf('Beginning at %d-%d-%d %02d:%02d.\n', begintime(1:5))

    out = struct();    
    % initial sigma-boxconstraint values for grid search
    out(1).sigma = params.initial_sigma;
    out(1).boxconstraint = params.initial_boxconstraint;
    
    % refine sigma-bc
    for r=1:params.grid_refine
        fprintf('Step %d crossval with %d parameter combinations.\n', ...
                r, length(out(r).sigma)*length(out(r).boxconstraint))
        if r>1
            esttime = round(time/numcv*length(out(r).sigma)*length(out(r).boxconstraint));
            estendt = datevec(datenum(0,0,0,0,0,esttime)+now);
            fprintf('This will take about %dm %ds, ending at %02d:%02d.\n', ...
                    floor(esttime/60), mod(esttime,60), fix(estendt(4:5)))
        end
      
        % avoid nested loops by linearizing Z-C matrix
        out(r).l_sigma = reshape( diag(out(r).sigma)*ones(length(out(r).sigma),...
                                                          length(out(r).boxconstraint)), 1, []);
        out(r).l_boxc  = reshape( ones(length(out(r).sigma),...
                                       length(out(r).boxconstraint))*diag(out(r).boxconstraint), 1, []);

        N = length(out(r).l_sigma);
        T = params.num_iterations;

        % results for current r
        res = cell(N,T,5,6);
      
        % ignore flag, avoid trying nonconvergent values
        ignore = zeros(size(out(r).l_sigma));

        % details for each iteration
        out(r).iter = struct();

        % featureset indexes
        fidx = [1,66;1,32;33,36;37,59;60,66];
      
        for t=1:T
          
            % shuffle data and separate labels
            train_data = shuffle( [  train.real(  tr_real(:,mod(t,params.num_partitions)+1),:); ...
                                train.pseudo(tr_pseudo(:,mod(t,params.num_partitions)+1),:)] );

            out(r).iter(t).train_ids  = train_data(:,68:70);
            train_lbls                   = train_data(:,67);
            out(r).iter(t).train_lbls = train_lbls;          
            train_data                   = train_data(:,1:66);
          
            test_real   =   train.real(  ts_real(:,mod(t,params.num_partitions)+1),1:66);
            test_pseudo = train.pseudo(ts_pseudo(:,mod(t,params.num_partitions)+1),1:66);

            out(r).iter(t).test_real_ids   =   train.real(  ts_real(:,mod(t,params.num_partitions)+1),68:70);
            out(r).iter(t).test_pseudo_ids = train.pseudo(ts_pseudo(:,mod(t,params.num_partitions)+1),68:70);
          
            parfor n=1:N
                if ignore(n) continue; end
                auxr = res(n,:,:,:);
                for f=params.featsets
                    try
                        model = svmtrain(train_data(:,fidx(f,1):fidx(f,2)),train_lbls, ...
                                         'Kernel_Function','rbf', ...
                                         'rbf_sigma',out(r).l_sigma(n), ...
                                         'boxconstraint',out(r).l_boxc(n));

                        res_r = round(svmclassify(model, test_real(:,fidx(f,1):fidx(f,2))));
                        res_p = round(svmclassify(model, test_pseudo(:,fidx(f,1):fidx(f,2))));
                      
                        Se = mean( res_r == 1 );
                        Sp = mean( res_p == -1 );
                        Gm = geomean( [Se Sp] );

                        auxr(1,t,f,1:3) = { Se, Sp, Gm };

                        % ignore this paramset if it's too bad
                        if Gm < 0.6
                            ignore(n) = 1;
                            continue
                        end
                      
                        % save only 'good' models
                        if Gm > 0.6
                            auxr(1,t,f,4:6) = { res_r, res_p, model };
                        end
                                            
                    catch e
                        % ignore this paramset if it does not converge
                        if strfind(e.identifier,'NoConvergence')
                            if f == 1
                                ignore(n) = 1;
                            end
                        else
                            fprintf('err: %s / %s', e.identifier, e.message)
                        end
                    end % try
                end % for f
              
                % save results to cell array
                res(n,:,:,:) = auxr;
            end % parfor n

            out(r).raw_results = res;
        end % for t

        out(r).feat = struct();
        avgbest = zeros(5,N);
      
        % for every feature
        for f = params.featsets
            % save avg performance
            out(r).feat(f).se = mean( cellfun(@zerofill,res(:,:,f,1)'), 1);
            out(r).feat(f).sp = mean( cellfun(@zerofill,res(:,:,f,2)'), 1);
            out(r).feat(f).gm = mean( cellfun(@zerofill,res(:,:,f,3)'), 1);
            % highlight best-performing paramsets
            out(r).feat(f).best = [ abs(out(r).feat(f).gm-max(out(r).feat(f).gm)) < 4^(-r-2) ];

            for d=find(out(r).feat(f).best)
                fprintf('Step %d, feat %d: SE %8.6f SP %8.6f GM %8.6f for log(Z,C) = %8.6f,%8.6f idx %d\n', ...
                        r, f, out(r).feat(f).se(d), out(r).feat(f).sp(d), out(r).feat(f).gm(d), ...
                        log(out(r).l_sigma(d)), log(out(r).l_boxc(d)),d);
            end % for d
          
            % fill column of average-best matrix
            avgbest(f,:) = out(r).feat(f).best;
        end
        avgbest = mean(avgbest(params.featsets,:),1);

        % pick best parameters
        out(r).best = [ abs(avgbest-max(avgbest)) < 0.1 ];
      
        % refine grid around central value n
        neighbor = @(n,d,w) exp([log(n)-w/2^(d-1):1/2^(d-1):log(n)+w/2^(d-1)]);
            
        % new parameters for next iteration
        ns = [];
        nc = [];
        for d=find(out(r).best)
            fprintf('Step %d: SE %8.6f SP %8.6f GM %8.6f for log(Z,C) = %8.6f,%8.6f idx %d\n', ...
                    r, out(r).feat(params.featsets(1)).se(d), ...
                    out(r).feat(params.featsets(1)).sp(d), ...
                    out(r).feat(params.featsets(1)).gm(d), ...
                    log(out(r).l_sigma(d)), log(out(r).l_boxc(d)),d);
            % append new values to ns,nc
            ns = [ ns; neighbor(out(r).l_sigma(d),r,4)'];
            nc = [ nc, neighbor(out(r).l_boxc(d), r,4) ];
        end % for d
      
        % delete non-best svm models as they take up too much space
        for n=find(1-out(r).best)
            for t=1:params.num_iterations
                out(r).iter(t).paramtest(n).model = 'discarded';
            end
        end

        % values for next grid refine
        if r < params.grid_refine
            out(r+1).precision     = 1/2^(r-1); % as in neighbor function
            out(r+1).sigma         = logunique( ns, 1e-5 );
            out(r+1).boxconstraint = logunique( nc, 1e-5 );
        end
      
      numcv = numcv + length(out(r).sigma)*length(out(r).boxconstraint);
      time = round(etime(clock,begintime));
      fprintf( 'Time: %02d:%02d.\n', floor(time/60), mod(time,60))
    
    end % for r    
    % matlabpool close

end