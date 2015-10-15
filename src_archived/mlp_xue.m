function mlp_xue ( num_iterations, train_function )

    if nargin < 2
    if nargin < 1
        num_iterations = 10
    end
        train_function = 'trainscg'
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

    n_hidden = [5:14];

    shuffle = @(x) x(randsample(size(x,1),size(x,1)),:);

    se = zeros( num_iterations, length(n_hidden) ); % sensitivity
    sp = zeros( num_iterations, length(n_hidden) ); % specificity

    % SVM training and crossval
    [tr_real ts_real] = partset(real, 163);
    [ts_pseudo tr_pseudo] = partset(pseudo,1000,1168);
    % VER: el training set pseudo es totalmente diferente
    % en cada iteración

    fprintf('REAL %d PSEUDO %d TR+ %d TR- %d TE+ %d TE- %d\n', ...
            size(real,1), size(pseudo,1), size(tr_real,1), ...
            size(tr_pseudo,1), size(ts_real,1), size(ts_pseudo, 1))

    ir = 1;
    ip = 1;
    for t=1:num_iterations
        if mod(t, floor(num_iterations/20))==0
            fprintf('%d%% ', floor(100*t/num_iterations));
        end
        if ir > size(tr_real,2)
	    [tr_real ts_real] = partset(real,163); ir=1;
        end
        if ip > size(tr_pseudo,2)
	    [ts_pseudo tr_pseudo] = partset(pseudo,1000,11168); ip=1;
        end

        train_data = shuffle( [  real(  tr_real(:,ir),1:67); ...
                            pseudo(tr_pseudo(:,ip),1:67)] );

        train_lbls = [train_data(:,67), -train_data(:,67)];
        [train_data f s] = scale_sym(train_data(:,1:66));

        test_real   = scale_sym(  real(  ts_real(:,ir),1:66),f,s);
        test_pseudo = scale_sym(pseudo(ts_pseudo(:,ip),1:66),f,s);

        parfor n=1:length(n_hidden)
            if n_hidden(n) < 1 continue; end

            net = patternnet( n_hidden(n) );

            net.trainFcn = train_function;
            net.trainParam.showWindow = 0;
            %net.trainParam.show = 2000;
            net.trainParam.time = 10;
            net.trainParam.epochs = 2000000000000;

            net = init(net);
            net = train(net, train_data', train_lbls');

            res_r = round(net(test_real'))';
            res_p = round(net(test_pseudo'))';

            se(t,n) = mean( res_r(:,1) == 1 );
            sp(t,n) = mean( res_p(:,2) == 1 );

        end
    end

    save( ['mlp_xue_' datestr(now,'yyyymmdd_HHMMSS') '.mat'],'se','sp');


    gm = geomean([mean(se,1);mean(sp,1)],1);
    se = mean(se,1);
    sp = mean(sp,1);

    fprintf('\n')
    for n=1:length(n_hidden)
        fprintf('N_HIDDEN %d : SE %8.6f SP %8.6f GM %8.6f\n', ...
                n_hidden(n) , se(n), sp(n), gm(n));
    end
    matlabpool close
end
