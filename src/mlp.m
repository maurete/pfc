function mlp ( dataset, featset, seed )
    
    if nargin < 3
        seed = mod(5829,2^32);
        if nargin < 2
            featset = 1;
            if nargin < 1
                dataset = 'hsa';
            end
        end
    end
    
    dlm_outfile = 'results.tsv';
    if ~exist( dlm_outfile )
        fid = fopen( dlm_outfile, 'a' );
        fprintf( fid, [ 'id\tseed\ttrain/test\tsetup\tdataset\tfeatset\t'...
                        'classifier\tparam1\tparam2\tse\tsp\tgm/perf\n' ] ); 
        fclose(fid);
    end

    fprintf('#\n> begin mlp\n#\n' );
    % keep record of this experiment for review
    rec = struct();
    
    %rec.random_seed = 562549009;
    %rec.random_seed = 562345829;
    %rec.random_seed = mod(5829,2^32);    
    rec.random_seed = seed;    

    % feature sets with which to train: 
    % 1=all, 2=triplet, 3=triplet-extra, 
    % 4=sequence, 5=structure
    rec.feature_set = featset;
    % featureset indexes
    fidx = { 1:66; 1:32; 33:36; 37:59; 60:66; 1:36; [1:36 60:66]; ...
             37:66; 1:59; 33:66; [33:36 60:66]; 33:59; [1:32 60:66]; ...
             [1:32 37:59]; [1:32 37:66] };
    fname = {'all-features', 'triplet', 'triplet-extra', 'sequence', ...
             'structure', 'triplet+extra', 'not-sequence', ...
             'seq+struct', 'not-structure', 'not-triplet', 'extra+str', ...
             'extra+sequence', 'triplet+structure', 'triplet+sequence', ...
             'not-extra' };
    features = fidx{featset};
    
    rec.num_partitions = 5;
    rec.num_iterations = 5;
    rec.hidden_sizes   = [5:25];
    rec.train_function = 'trainscg';
    
    % aux functions
    pick      = @(x,n) x(randsample(size(x,1),min(size(x,1),n)),:);
    shuffle   = @(x)   x(randsample(size(x,1),size(x,1)),:);
    stpick    = @(x,n) x(strandsample(rec.random_seed,size(x,1),min(size(x,1),n)),:);
    stshuffle = @(x)   x(strandsample(rec.random_seed,size(x,1),size(x,1)),:);
    function o=zerofill(i),o=0;if i,o=i;end,end
    
    rec.begintime = clock;
    rec.time = 0;
    rec.numcv = 0;

    [rec.train rec.test] = load_data( dataset, rec.random_seed, true);
    
    fprintf('> dataset\t%s\n', dataset );
    fprintf('> featureset\t%s\n', fname{featset} );
    
    real   = rec.train.real;
    pseudo = rec.train.pseudo;

    % generate 10 cross-validation partitions
    [tr_real ts_real]     = stpart(rec.random_seed, rec.train.real, rec.num_partitions);
    [tr_pseudo ts_pseudo] = stpart(rec.random_seed, rec.train.pseudo, rec.num_partitions);
    
    fprintf([ '# begin cross-validation training\n> partitions\t%d\n#\n', ...
              '# dataset\tsize\t#train\t#test\n', ...
              '# -------\t----\t------\t-----\n', ...
              '> real\t\t%d\t%d\t%d\n', ...
              '> pseudo\t%d\t%d\t%d\n#\n' ], ...
            rec.num_partitions, size(rec.train.real,1), size(tr_real,1), size(ts_real,1), ...
            size(rec.train.pseudo,1), size(tr_pseudo,1), size(ts_pseudo,1) );
    
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

    N = length(rec.hidden_sizes);
    T = rec.num_iterations;

    % results for current r
    res = cell(N,T,6);
      
    % details for each iteration
    rec.iter = struct();
      
    for t=1:T
          
        % shuffle data and separate labels
        train_data = shuffle( [  real(  tr_real(:,mod(t,rec.num_partitions)+1),:); ...
                            pseudo(tr_pseudo(:,mod(t,rec.num_partitions)+1),:)] );

        rec.iter(t).train_ids  = train_data(:,68:70);
        train_lbls             = [train_data(:,67), -train_data(:,67)];
        rec.iter(t).train_lbls = train_lbls;          
        train_data             = train_data(:,1:66);
          
        test_real   =   real(  ts_real(:,mod(t,rec.num_partitions)+1),1:66);
        test_pseudo = pseudo(ts_pseudo(:,mod(t,rec.num_partitions)+1),1:66);

        rec.iter(t).test_real_ids   =   real(  ts_real(:,mod(t,rec.num_partitions)+1),68:70);
        rec.iter(t).test_pseudo_ids = pseudo(ts_pseudo(:,mod(t,rec.num_partitions)+1),68:70);
          
        parfor n=1:N
            auxr = res(n,:,:);
            try
                net = patternnet( rec.hidden_sizes(n) );
                    
                net.trainFcn = rec.train_function;
                net.trainParam.showWindow = 0;
                %net.trainParam.show = 2000;
                net.trainParam.time = 10;
                net.trainParam.epochs = 2000000000000;
                
                net = init(net);
                net = train(net, train_data(:,features)', train_lbls');

                %res_r = round(net(test_real'))';
                %res_p = round(net(test_pseudo'))';
            
                res_r = sign(net(test_real(:,features)'))';
                res_p = sign(net(test_pseudo(:,features)'))';

                Se = mean( res_r(:,1) == 1 );
                Sp = mean( res_p(:,2) == 1 );
                Gm = geomean( [Se Sp] );

                auxr(1,t,1:3) = { Se, Sp, Gm };
                      
                % save only 'good' models
                if Gm > 0.5
                    auxr(1,t,4:6) = { res_r, res_p, net };
                end
                                            
            catch e
                fprintf('! %s / %s', e.identifier, e.message)
            end % try
              
              % save results to cell array
              res(n,:,:) = auxr;
        end % parfor n

        rec.raw_results = res;
    end % for t

    % save avg performance
    rec.se = mean( cellfun(@zerofill,res(:,:,1)'), 1);
    rec.sp = mean( cellfun(@zerofill,res(:,:,2)'), 1);
    rec.gm = mean( cellfun(@zerofill,res(:,:,3)'), 1);
    % highlight best-performing paramsets
    rec.best = [ abs(rec.gm-max(rec.gm)) < 4^(-1-2) ];

    if max(rec.gm) == 0
        fprintf('! no convergence, sorry\n')
        fid = fopen( dlm_outfile, 'a' );
        fprintf( fid, '%f\t%d\t%s\t%s\t%s\t%d\t%s\t%9.8g\t%9.8g\t%9.8g\t%9.8g\t%9.8g\n', ...
                 datenum(rec.begintime), seed, 'train', dataset, 'train', featset, ...
                 'mlp', [], [], 0, 0, 0 );
        for i=1:length(rec.test)
            fprintf( fid, '%f\t%d\t%s\t%s\t%s\t%d\t%s\t%9.8g\t%9.8g\t%9.8g\t%9.8g\t%9.8g\n', ...
                 datenum(rec.begintime), seed, 'test', dataset, rec.test(i).name, featset, ...
                     'mlp', [], [], [], [], 0 );
        end
        fclose(fid)
        return
    end

    fprintf('#\n# idx\t#hidden\t\tsensitivity\tspecificity\tgeomean\n');
    fprintf(   '# ---\t-------\t\t-----------\t-----------\t-------\n');
    for d=find(rec.best)
        fprintf('< %d\t%d\t%8.6f\t%8.6f\t%8.6f\n', ...
                  d, rec.hidden_sizes(d), ...
                  rec.se(d), ...
                  rec.sp(d), ...
                  rec.gm(d) );
    end % for d
          
    rec.time = round(etime(clock,rec.begintime));
    fprintf( '#\n> time\t%02d:%02d\n', floor(rec.time/60), mod(rec.time,60))

    % matlabpool close

    % perform classification on test datasets
    bidx = find(rec.best,1,'first');

    % write tsv-data
    fid = fopen( dlm_outfile, 'a' );
    % fprintf( fid, [ 'id\ttrain/test\tsetup\tdataset\tfeatset\t'...
    %                 'classifier\tparam1\tparam2\tse\tsp\tgm/perf\n' ] ); 
    fprintf( fid, '%f\t%d\t%s\t%s\t%s\t%d\t%s\t%9.8g\t%9.8g\t%9.8g\t%9.8g\t%9.8g\n', ...
                 datenum(rec.begintime), seed, 'train', dataset, 'train', featset, 'mlp', ...
             rec.hidden_sizes(bidx), [], rec.se(bidx), rec.sp(bidx), rec.gm(bidx) );
    
    if max(rec.gm) < 0.6
        fprintf('! train CV rate too low, not testing\n')
        for i=1:length(rec.test)
            fprintf( fid, '%f\t%d\t%s\t%s\t%s\t%d\t%s\t%9.8g\t%9.8g\t%9.8g\t%9.8g\t%9.8g\n', ...
                 datenum(rec.begintime), seed, 'test', dataset, rec.test(i).name, featset, ...
                     'mlp', [], [], [], [], 0 );
        end
        fclose(fid)
        return
    end


    
    fprintf('#\n# begin testing\n');
    fprintf('# \t\tdataset\t\t\tclass\tsize\tperformance\n');
    fprintf('# \t\t-------\t\t\t-----\t----\t-----------\n');

    for i=1:length(rec.test)
        rec.test(i).cls_results = zeros(size(rec.test(i).data,1),rec.num_iterations);
        rec.test(i).performance = zeros(1,rec.num_iterations); 
        
        for t=1:rec.num_iterations
            net = rec.raw_results{bidx,t,6};
            res = sign(net(rec.test(i).data(:,features)'))';
            rec.test(i).cls_results(:,t) = res(:,1).*(res(:,1)~=res(:,2));
            rec.test(i).performance(t)   = mean( ...
                rec.test(i).cls_results(:,t) == rec.test(i).class);
        end
        rec.test(i).avg_performance =  mean(rec.test(i).performance);

        fprintf('+ %32s\t%d\t%d\t%8.6f\n',...
                rec.test(i).name, rec.test(i).class, size(rec.test(i).data,1), rec.test(i).avg_performance);

        fprintf( fid, '%f\t%d\t%s\t%s\t%s\t%d\t%s\t%9.8g\t%9.8g\t%9.8g\t%9.8g\t%9.8g\n', ...
                 datenum(rec.begintime), seed, 'test', dataset, rec.test(i).name, featset, ...
                 'mlp', rec.hidden_sizes(bidx), [], [], [], rec.test(i).avg_performance );
        
        
        % clear data for saving space
        rec.test(i).data = [];
    end
    fclose(fid);
    
    fprintf( ['#\n# saving results to ' './results/mlp-' ...
             datestr(rec.begintime,'yyyy-mm-dd_HH.MM.SS') '.mat\n']);
    save( ['./results/mlp-' datestr(rec.begintime,'yyyy-mm-dd_HH.MM.SS') '.mat'],'-struct', 'rec');

end
