function mlp ( dataset, featset, balance, randseed, tabfile, data )

    cached_data = true;
    if nargin < 6, cached_data = false; end
    if nargin < 5, tabfile = 'resultsv3.tsv'; end
    if nargin < 4, randseed = [1135 223626 353 5341]; end
    if nargin < 3, balance = 0; end
    com = common;
    features = com.fidx{featset};

    % number of random seeds
    Nrs = length(randseed);

    % number of partitions
    Np = 5;

    % hidden layer sizes to try
    hidden = [5:25];

    % MLP train function
    trainfunc = 'trainscg';

    % file where to save tabulated train/test data
    % tabfile = 'resultsv3.tsv';

    % classifier name used for output
    selfname = 'mlp';
    if balance, selfname = 'mlp-bal';end

    fprintf('#\n> begin\t%s\n#\n', selfname);

    time = com.time_init();

    %%% Load data %%%

    if ~ cached_data
        data = struct();
        for i=1:Nrs
            [ data(i).train data(i).test] = load_data( dataset, randseed(i), false);
            if balance, data(i).train.pseudo = ...
                    com.stpick(randseed(i), data(i).train.pseudo, size(data(i).train.real,1));
            end
            % generate CV partitions
            [data(i).tr_real data(i).cv_real] = ...
                stpart(randseed(i), data(i).train.real, Np);
            [data(i).tr_pseudo data(i).cv_pseudo] = ...
                stpart(randseed(i), data(i).train.pseudo, Np);
        end
    end

    %%% timing and output %%%

    time = com.time_tick(time,0);
    com.write_init(tabfile);
    com.print_train_info(dataset, featset, data);

    %%% create matlab pool %%%

    com.init_matlabpool();

    %%% MLP training %%%

    Nh = length(hidden);

    % crossval results
    cv_res = zeros(1,Nh);

    for s = 1:Nrs % random seeds
        for p=1:Np % partitions

            % shuffle data and separate labels
            traindata = com.shuffle([data(s).train.real(  data(s).tr_real(  :,p),:); ...
                                     data(s).train.pseudo(data(s).tr_pseudo(:,p),:)] );
            trainlabels = [traindata(:,67), -traindata(:,67)];

            test_real   = data(s).train.real(  data(s).cv_real(  :,p),:);
            test_pseudo = data(s).train.pseudo(data(s).cv_pseudo(:,p),:);

            % parfor results
            pf_res = zeros(1,Nh);
            parfor h=1:Nh
                Gm = 0;
                try
                    net = patternnet( hidden(h) );
                    net.trainFcn = trainfunc;
                    net.trainParam.showWindow = 0;
                    net.trainParam.time = 10;
                    net.trainParam.epochs = 2000000000000;
                    net = init(net);
                    net = train(net, traindata(:,features)', trainlabels');

                    res_r = sign(net(test_real(:,features)'))';
                    res_p = sign(net(test_pseudo(:,features)'))';

                    Se = mean( res_r(:,1) == 1 );
                    Sp = mean( res_p(:,2) == 1 );
                    Gm = geomean( [Se Sp] );

                    % save Gm to results array
                    pf_res(h) = Gm;

                catch e
                    fprintf('! fatal: %s / %s', e.identifier, e.message)
                end % try
            end % parfor h

            cv_res = cv_res + pf_res/(Np*Nrs);

            fprintf('.')

        end % for p
    end % for s

    % select best-performing paramsets
    better = [ abs(cv_res-max(cv_res)) < 4^(-1-2) ];
    best = [ abs(cv_res-max(cv_res)) < 0.00001 ];

    fprintf('\n# idx\t#hidden\t\tgm\n');
    fprintf(  '# ---\t-------\t\t-------\n');
    for d=find(better)
        fprintf('< %d\t%d\t\t%8.6f\n', d, hidden(d), cv_res(d) );
    end % for d

    time = com.time_tick(time,Nh);

    bidx = find(best,1,'first');

    com.write_train_info(tabfile, dataset, featset, selfname, ...
                         hidden(bidx), 0, cv_res(bidx));

    %%% test best-performing parameters %%%

    fprintf('#\n+ test\n+ hidden\t%d\n', hidden(bidx))

    res = com.run_tests(data,featset,randseed,selfname,hidden(bidx),0);

    com.write_test_info(tabfile, dataset, featset, selfname, ...
                         hidden(bidx), 0, res);

    com.print_test_info(res);
    com.time_tick(time,0);
end