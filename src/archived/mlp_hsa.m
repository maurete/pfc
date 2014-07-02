function mlp_hsa
    
    % keep record of this experiment for review
    rec = struct();
    
    %rec.random_seed = 562549009;
    %rec.random_seed = 562345829;
    rec.random_seed = mod(5829,2^32);    
    
    % feature sets with which to train: 
    % 1=all, 2=triplet, 3=triplet-extra, 
    % 4=sequence, 5=structure
    rec.featsets = 1:5;
    
    rec.num_partitions = 5;
    rec.num_iterations = 5;
    rec.hidden_sizes   = [5:14];
    rec.train_function = 'trainscg';
    
    % aux functions
    pick      = @(x,n) x(randsample(size(x,1),min(size(x,1),n)),:);
    shuffle   = @(x)   x(randsample(size(x,1),size(x,1)),:);
    stpick    = @(x,n) x(strandsample(rec.random_seed,size(x,1),min(size(x,1),n)),:);
    stshuffle = @(x)   x(strandsample(rec.random_seed,size(x,1),size(x,1)),:);
    function o=zerofill(i),o=0;if i,o=i;end,end
    
    % load train datasets
    real1   = loadset('mirbase20-nr','human', 0); % 1265 hsa entries
    pseudo1 = loadset('coding','all', 1);         % 8494 hsa-only dataset
    pseudo2 = loadset('other-ncrna','all', 2);    % 129  hsa-only dataset

    % test datasets (not used for CV)
    rec.test = struct();
    rec.test(1).name  = 'mirbase20-other-species';
    rec.test(1).class = 1;
    rec.test(1).data  = loadset('mirbase20-nr','non-human', 3);

    % pick random elements for training with ratio 1real:2pseudo
    real   = stpick(real1, 1260); % 1260 real
    pseudo = stshuffle([ stpick(pseudo1,2391); pseudo2 ]); % 2520 pseudo
    
    % scale the data to the range [-1:1]
    [real(:,1:66) f s] = scale_data(real(:,1:66));
    [pseudo(:,1:66)]   = scale_data(pseudo(:,1:66),f,s);

    rec.scale_f = f;
    rec.scale_s = s;
    
    % generate 10 cross-validation partitions
    [tr_real ts_real]     = stpart(rec.random_seed, real, rec.num_partitions);
    [tr_pseudo ts_pseudo] = stpart(rec.random_seed, pseudo, rec.num_partitions);
    
    fprintf('REAL %d PSEUDO %d TR+ %d TR- %d TE+ %d TE- %d\n', ...
            size(real,1), size(pseudo,1), size(tr_real,1), ...
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

    rec.begintime = clock;
    rec.time = 0;
    fprintf('Beginning at %d-%d-%d %02d:%02d.\n', rec.begintime(1:5))

    N = length(rec.hidden_sizes);
    T = rec.num_iterations;

    % results for current r
    res = cell(N,T,5,6);
      
    % details for each iteration
    rec.iter = struct();

    % featureset indexes
    fidx = [1,66;1,32;33,36;37,59;60,66];
      
    for t=1:T
          
        % shuffle data and separate labels
        train_data = shuffle( [  real(  tr_real(:,mod(t,rec.num_partitions)+1),:); ...
                            pseudo(tr_pseudo(:,mod(t,rec.num_partitions)+1),:)] );

        rec.iter(t).train_ids  = train_data(:,68:70);
        train_lbls                   = [train_data(:,67), -train_data(:,67)];
        rec.iter(t).train_lbls = train_lbls;          
        train_data                   = train_data(:,1:66);
          
        test_real   =   real(  ts_real(:,mod(t,rec.num_partitions)+1),1:66);
        test_pseudo = pseudo(ts_pseudo(:,mod(t,rec.num_partitions)+1),1:66);

        rec.iter(t).test_real_ids   =   real(  ts_real(:,mod(t,rec.num_partitions)+1),68:70);
        rec.iter(t).test_pseudo_ids = pseudo(ts_pseudo(:,mod(t,rec.num_partitions)+1),68:70);
          
        parfor n=1:N
            auxr = res(n,:,:,:);
            for f=rec.featsets
                try
                    net = patternnet( rec.hidden_sizes(n) );
                    
                    net.trainFcn = rec.train_function;
                    net.trainParam.showWindow = 0;
                    %net.trainParam.show = 2000;
                    net.trainParam.time = 10;
                    net.trainParam.epochs = 2000000000000;
                
                    net = init(net);
                    net = train(net, train_data(:,fidx(f,1):fidx(f,2))', train_lbls');

                    res_r = round(net(test_real'))';
                    res_p = round(net(test_pseudo'))';
            
                    res_r = round(net(test_real(:,fidx(f,1):fidx(f,2))'))';
                    res_p = round(net(test_pseudo(:,fidx(f,1):fidx(f,2))'))';

                    Se = mean( res_r(:,1) == 1 );
                    Sp = mean( res_p(:,2) == 1 );
                    Gm = geomean( [Se Sp] );

                    auxr(1,t,f,1:3) = { Se, Sp, Gm };
                      
                    % save only 'good' models
                    if Gm > 0.5
                        auxr(1,t,f,4:6) = { res_r, res_p, net };
                    end
                                            
                  catch e
                      fprintf('err: %s / %s', e.identifier, e.message)
                  end % try
              end % for f
              
              % save results to cell array
              res(n,:,:,:) = auxr;
        end % parfor n

        rec.raw_results = res;
    end % for t

    rec.feat = struct();
    avgbest = zeros(5,N);
      
    % for every feature
    for f = rec.featsets
        % save avg performance
        rec.feat(f).se = mean( cellfun(@zerofill,res(:,:,f,1)'), 1);
        rec.feat(f).sp = mean( cellfun(@zerofill,res(:,:,f,2)'), 1);
        rec.feat(f).gm = mean( cellfun(@zerofill,res(:,:,f,3)'), 1);
        % highlight best-performing paramsets
        rec.feat(f).best = [ abs(rec.feat(f).gm-max(rec.feat(f).gm)) < 4^(-1-2) ];

        for d=find(rec.feat(f).best)
            fprintf('feat %d: SE %8.6f SP %8.6f GM %8.6f for nhid = %d idx %d\n', ...
                    f, rec.feat(f).se(d), rec.feat(f).sp(d), rec.feat(f).gm(d), ...
                    rec.hidden_sizes(d),d);
        end % for d
          
        % fill column of average-best matrix
        avgbest(f,:) = rec.feat(f).best;
    end
    
    avgbest = mean(avgbest(rec.featsets,:),1);

    % pick best parameters
    rec.best = [ abs(avgbest-max(avgbest)) < 0.1 ];
                  
    for d=find(rec.best)
        fprintf('SE %8.6f SP %8.6f GM %8.6f for nhidden = %d idx %d\n', ...
                rec.feat(rec.featsets(1)).se(d), ...
                rec.feat(rec.featsets(1)).sp(d), ...
                rec.feat(rec.featsets(1)).gm(d), ...
                rec.hidden_sizes(d),d);
    end % for d
      
    rec.time = round(etime(clock,rec.begintime));
    fprintf( 'Time: %02d:%02d.\n', floor(rec.time/60), mod(rec.time,60))
    
    % matlabpool close

    % perform classification on test datasets
    bidx = find(rec.best,1,'first');
    
    for i=1:length(rec.test)
        rec.test(i).featset = struct();
        avgperf = [];
        
        scaled = scale_data(rec.test(i).data(:,1:66),rec.scale_f,rec.scale_s);

        for f = rec.featsets
            rec.test(i).featset(f).cls_results = zeros(size(rec.test(i).data,1),rec.num_iterations);
            rec.test(i).featset(f).performance = zeros(1,rec.num_iterations); 
        
            for t=1:rec.num_iterations
                net = rec.raw_results{bidx,t,f,6};
                res = round(net(scaled'))';
                rec.test(i).featset(f).cls_results(:,t) = res(:,1);
                rec.test(i).featset(f).performance(t)   = mean( ...
                    rec.test(i).featset(f).cls_results(:,t) == rec.test(i).class);
            end
            rec.test(i).featset(f).avg_performance =  mean(rec.test(i).featset(f).performance);
            avgperf = [avgperf rec.test(i).featset(f).avg_performance];
        end

        rec.test(i).avg_performance = mean(avgperf); 

        fprintf('test dataset %s: %d entries, avg performance %8.6f.\n',...
                rec.test(i).name, size(rec.test(i).data,1), rec.test(i).avg_performance);
        
        % clear data for saving space
        rec.test(i).data = [];
    end
    
    save( ['./results/mlp_hsa-' datestr(rec.begintime,'yyyy-mm-dd_HH.MM.SS') '.mat'],'-struct', 'rec');

end
