function mlp ( dataset, featset, balance, random_seeds )

    if nargin < 3, balance = 0; end
    if nargin < 4, random_seeds = [303456; 456789; 5829]; end

    % aux functions
    pick      = @(x,n) x(randsample(size(x,1),min(size(x,1),n)),:);
    shuffle   = @(x)   x(randsample(size(x,1),size(x,1)),:);
    stpick    = @(i,x,n) x(strandsample(random_seeds(i),size(x,1),min(size(x,1),n)),:);
    stshuffle = @(i,x)   x(strandsample(random_seeds(i),size(x,1),size(x,1)),:);
    function o=zerofill(i);o=0;if i;o=i;end;end;

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

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    fprintf('#\n> begin mlp\n#\n' );

    % keep record of this experiment for review
    S = struct();
    S.random_seeds = random_seeds;
    S.featureset = featset;
    S.partitions = 5;
    S.hidden_sizes = [5:25];
    S.train_function = 'trainscg';
    S.begintime = clock;
    S.time = 0;
    S.numcv = 0;

    S.data = struct();
    for i=1:length(S.random_seeds)
        [ S.data(i).train S.data(i).test] = load_data( dataset, S.random_seeds(i), false);
        if balance, S.data(i).train.pseudo = ...
                stpick(i, S.data(i).train.pseudo, size(S.data(i).train.real,1));
        end
        % generate CV partitions
        [S.data(i).cv_train_real S.data(i).cv_test_real] = ...
            stpart(S.random_seeds(i), S.data(i).train.real, S.partitions);
        [S.data(i).cv_train_pseudo S.data(i).cv_test_pseudo] = ...
            stpart(S.random_seeds(i), S.data(i).train.pseudo, S.partitions);
    end

    % file where to save tabulated train/test data
    tabfile = 'resultsv2.tsv'
    if ~exist( tabfile )
        fid = fopen( tabfile, 'a' );
        fprintf( fid, [ '#dsetup\tclass\tdataset\tfeatset\t' ...
                        'classifier\tparam1\tparam2\tP\n' ] );
        fclose(fid);
    end
    function writetab(fid,cls,dset,param,result)
        if balance, lbl='mlp-bal'; else lbl='mlp'; end
        fprintf(fid, '%s\t%d\t%s\t%d\t%s\t%9.8g\t%9.8g\t%9.8g\n', ...
                dataset, cls, dset, featset, lbl, param, [], result );
    end

    fprintf('> dataset\t%s\n', dataset );
    fprintf('> featureset\t%s\n', fname{featset} );
    fprintf([ '# begin cross-validation training\n> partitions\t%d\n#\n', ...
              '# dataset\tsize\t#train\t#test\n', ...
              '# -------\t----\t------\t-----\n', ...
              '> real\t\t%d\t%d\t%d\n', ...
              '> pseudo\t%d\t%d\t%d\n#\n' ], ...
            S.partitions, ...
            size(S.data(1).train.real,     1), ...
            size(S.data(1).cv_train_real,  1), ...
            size(S.data(1).cv_test_real,   1), ...
            size(S.data(1).train.pseudo,   1), ...
            size(S.data(1).cv_train_pseudo,1), ...
            size(S.data(1).cv_test_pseudo, 1));

    % create matlab pool
    num_workers = 12;
    if matlabpool('size') == 0
        while( num_workers > 1 )
            try
                matlabpool(num_workers);
                break
            catch e
                num_workers = num_workers-1;
                fprintf(['# trying %d workers\n'], num_workers);
            end
        end
    end
    fprintf('# using %d matlabpool workers\n', matlabpool('size'));

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Training

    N = length(S.hidden_sizes);
    RS = length(S.random_seeds);
    T = S.partitions;

    % results
    res = zeros(N,RS,T);
    % details for random partition
    rand = struct();

    for rs = 1:RS
        train_real        = S.data(rs).train.real;
        train_pseudo      = S.data(rs).train.pseudo;
        part_train_real   = S.data(rs).cv_train_real;
        part_train_pseudo = S.data(rs).cv_train_pseudo;
        part_test_real    = S.data(rs).cv_test_real;
        part_test_pseudo  = S.data(rs).cv_test_pseudo;

        % details for each iteration
        rand(rs).iter = struct();

        for t=1:T
            % shuffle data and separate labels
            traindata = shuffle( [  train_real(    part_train_real(:,mod(t,T)+1),:); ...
                                train_pseudo(part_train_pseudo(:,mod(t,T)+1),:)] );
            rand(rs).iter(t).train_ids  = traindata(:,68:70);
            train_lbls                  = [traindata(:,67), -traindata(:,67)];
            rand(rs).iter(t).train_lbls = train_lbls;
            traindata                   = traindata(:,1:66);

            test_real   =   train_real(  part_test_real(:,mod(t,T)+1),1:66);
            test_pseudo = train_pseudo(part_test_pseudo(:,mod(t,T)+1),1:66);

            rand(rs).iter(t).test_real_ids   = ...
                  train_real(  part_test_real(:,mod(t,T)+1),68:70);
            rand(rs).iter(t).test_pseudo_ids = ...
                  train_pseudo(part_test_pseudo(:,mod(t,T)+1),68:70);

            % parallel-for each parameter setting
            parfor n=1:N
                Gm = 0;
                try
                    net = patternnet( S.hidden_sizes(n) );

                    net.trainFcn = S.train_function;
                    net.trainParam.showWindow = 0;
                    %net.trainParam.show = 2000;
                    net.trainParam.time = 10;
                    net.trainParam.epochs = 2000000000000;

                    net = init(net);
                    net = train(net, traindata(:,features)', train_lbls');

                    res_r = sign(net(test_real(:,features)'))';
                    res_p = sign(net(test_pseudo(:,features)'))';

                    Se = mean( res_r(:,1) == 1 );
                    Sp = mean( res_p(:,2) == 1 );
                    Gm = geomean( [Se Sp] );

                catch e
                    fprintf('! %s / %s', e.identifier, e.message)
                end % try

                % save Gm to results array
                res(n,rs,t) = Gm;
            end % parfor n
        end % for t
    end % for rs

    % save avg performance
    S.gm = mean(mean(res,3),2)';

    % highlight best-performing paramsets
    S.better = [ abs(S.gm-max(S.gm)) < 4^(-1-2) ];
    S.best = [ abs(S.gm-max(S.gm)) < 0.00001 ];

    if max(S.gm) < 0.25
        fprintf('! no convergence, sorry\n')
        fid = fopen( tabfile, 'a' );
        writetab(fid, 0, 'train', [], 0)
        for i=1:length(S.data(1).test)
            writetab(fid, S.data(1).test(i).class, S.data(1).test(i).name,[],0)
        end
        fclose(fid)
        return
    end

    fprintf('#\n# idx\t#hidden\t\tgeomean\n');
    fprintf(   '# ---\t-------\t\t-------\n');
    for d=find(S.better)
        fprintf('< %d\t%d\t%8.6f\n', d, S.hidden_sizes(d), S.gm(d) );
    end % for d

    S.numcv = S.numcv + length(S.hidden_sizes);
    S.time  = round(etime(clock,S.begintime));
    fprintf( '#\n> time\t%02d:%02d\n', floor(S.time/60), mod(S.time,60))

    % perform classification on test datasets
    bidx = find(S.best,1,'first');

    % write tsv-data
    fid = fopen( tabfile, 'a' );
    writetab(fid, 0, 'train', S.hidden_sizes(bidx), S.gm(bidx))
    if max(S.gm) < 0.6
        fprintf('! train CV rate too low, not testing\n')
        for i=1:length(S.data(1).test)
            writetab(fid, S.data(1).test(i).class, S.data(1).test(i).name,[],0)
        end
        fclose(fid);
        return
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    fprintf('#\n# begin testing, H=%g\n',S.hidden_sizes(bidx));
    S.test = zeros(length(S.data(rs).test), length(S.random_seeds));

    for rs=1:length(S.random_seeds)

        train_real   = S.data(rs).train.real;
        train_pseudo = S.data(rs).train.pseudo;
        traindata    = stshuffle(rs,[train_real;train_pseudo]);
        train_lbls   = [traindata(:,67) -traindata(:,67)];

        net = patternnet( S.hidden_sizes(bidx) );
        net.trainFcn = S.train_function;
        net.trainParam.showWindow = 0;
        net.trainParam.time = 10;
        net.trainParam.epochs = 2000000000000;
        net = init(net);
        net = train(net, traindata(:,features)', train_lbls');

        for i=1:length(S.data(rs).test)
            res = sign(net(S.data(rs).test(i).data(:,features)'))';
            cls_results = res(:,1).*(res(:,1)~=res(:,2));
            S.test(i,rs) = mean( cls_results == S.data(rs).test(i).class);
        end
    end % for rs

    % print and write test results
    fprintf('# \t\tdataset\t\t\tclass\tsize\tperformance\n');
    fprintf('# \t\t-------\t\t\t-----\t----\t-----------\n');
    fid = fopen( tabfile, 'a' );
    for i=1:length(S.data(1).test)
        fprintf('+ %32s\t%d\t%d\t%8.6f\n',...
                S.data(1).test(i).name, S.data(1).test(i).class, ...
                size(S.data(1).test(i).data,1), mean(S.test(i,:)));

        writetab(fid, S.data(1).test(i).class, S.data(1).test(i).name, ...
                 S.hidden_sizes(bidx),mean(S.test(i,:)))
    end
    fclose(fid);

end
