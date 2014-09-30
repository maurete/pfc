function mlp ( dataset, featset, balance, randseed, npart, crit_mad, tabfile, data )

    if nargin < 8, data = false; end
    if nargin < 7, tabfile = 'resultsv3.tsv'; end
    if nargin < 6, crit_mad = false; end
    if nargin < 5, npart = 40; end
    if nargin < 4, randseed = 1135; end
    if nargin < 3, balance = 0; end

    com = common;
    features = com.fidx{featset};

    % classifier name used for output
    selfname = 'mlp';
    if balance, selfname = 'mlp-bal';end

    % use bootstrap if number of partitions specified is < 1
    bootstrap = false;
    if npart < 1
        bootstrap = true;
        % max bootstrap iterations
        Np = 200;
    else
        % number of partitions
        Np = npart;
    end

    % number of repeats for mlp
    Nr = 5;

    % MLP train function
    trainfunc = 'trainscg';

    % hidden layer sizes to try
    hidden = [5:25];
    Nh = length(hidden);
    
    fprintf('#\n> begin\t%s\n#\n', selfname);

    time = com.time_init();

    %%% Load data %%%

    if ~ data
        data = struct();
        % if bootstrap is true, load_data loads non-partitioned data in extra b_ fields
        [data.train data.test] = load_data(dataset, randseed, true, bootstrap);
        
        if ~bootstrap
            % if not bootstrap (=> cv) generate CV partitions
            [data.train.tr_real data.train.cv_real] = ...
                stpart(randseed, data.train.real, Np, 0.2);
            [data.train.tr_pseudo data.train.cv_pseudo] = ...
                stpart(randseed, data.train.pseudo, Np, 0.2);
        end
    
        % if pseudo balancing requested, discard some elements from the negative set
        if balance, data.train.pseudo = ...
                com.stpick(randseed+435, data.train.pseudo, size(data.train.real,1));
            data.train.b_pseudo_size = data.train.b_real_size;
        end

    end

    %%% timing and output %%%

    time = com.time_tick(time,0);
    com.write_init(tabfile);
    com.print_train_info(dataset, featset, data.train);

    %%% create matlab pool %%%

    com.init_matlabpool();

    %%% MLP training %%%
    
    % aggregate Gm,mad for each hidden size
    r_gm = [];
    r_mad = [];
    r_aux = [];

    for p=1:Np % partitions
        
        if bootstrap
            % generate new bootstrap partitions
            [tr_real ts_real] = bstpart(randseed+p, size(data.train.b_real,1), ...
                                        data.train.b_real_size, 0.2); 
            [tr_pseu ts_pseu] = bstpart(randseed+p, size(data.train.b_pseudo,1), ...
                                        data.train.b_pseudo_size, 0.2);
                
            traindata = com.shuffle([data.train.b_real(tr_real,:); ...
                                data.train.b_pseudo(tr_pseu,:)] );
            test_real   = data.train.b_real(  ts_real,:);
            test_pseudo = data.train.b_pseudo(ts_pseu,:);
        else
            % select Pth crossval partition
            traindata = com.shuffle([data.train.real(  data.train.tr_real( :,p),:); ...
                                data.train.pseudo(data.train.tr_pseudo(:,p),:)] );
            test_real   = data.train.real(  data.train.cv_real(  :,p),:);
            test_pseudo = data.train.pseudo(data.train.cv_pseudo(:,p),:);
        end

        % separate labels from training data
        trainlabels = [traindata(:,67), -traindata(:,67)];
        
        % parfor results
        pf_res = zeros(Nh,Nr);
        
        for r=1:Nr
            parfor h=1:Nh
                Gm = 0;
                try
                    net = patternnet( hidden(h) );
                    net.trainFcn = trainfunc;
                    net.trainParam.showWindow = 0;
                    %net.trainParam.time = 10;
                    %net.trainParam.epochs = 2000000000000;
                    net = init(net);
                    net = configure(net, traindata(:,features)', trainlabels');
                    net = train(net, traindata(:,features)', trainlabels');
                    res_r = sign(net(test_real(:,features)'))';
                    res_p = sign(net(test_pseudo(:,features)'))';

                    Se = mean( res_r(:,1) == 1 );
                    Sp = mean( res_p(:,2) == 1 );
                    Gm = geomean( [Se Sp] );

                    % save Gm to results array
                    pf_res(h,r) = Gm;

                catch e
                    fprintf('! fatal: %s / %s', e.identifier, e.message)
                end % try
            end % parfor h
        end % for r

        % show some progress indicator
        fprintf('.')

        % gm, mad averaged for Nr repeats
        avg_gm = mean(pf_res,2);
        avg_mad = mad(pf_res,0,2);
        
        % append gm, mad to global results
        r_gm = [r_gm, avg_gm];
        r_mad = [r_mad, avg_mad];
        
        % compute aux = mean gm - mean abs deviation for results
        if crit_mad, if p>1, r_aux = [r_aux, mean(r_gm,2)-mad(r_gm,0,2)]; end                
        else,        if p>1, r_aux = [r_aux, mean(r_gm,2)]; end, end                

        % test for convergence on bootstrap
        if bootstrap && p>10
            % assuming mad -> constant on p -> Inf,
            % pf_aux shoud converge to constant values
            area = sum(abs(r_aux(:,p-1)-r_aux(:,p-2)));
            if area < 0.001*size(r_aux,1)
                % break if each paramset on avg varies less than 0.1%
                break;
            else
                fprintf(' %4.4f ', area/size(r_aux,1))
            end
        end

    end % for p

    % plot pf_aux convergence
    plot(hidden,r_aux)

    % keep only averaged r_gm, r_mad, and last column of r_aux
    r_gm = mean(r_gm,2);
    r_mad = mean(r_mad,2);
    r_aux = r_aux(:,end);

    % select best values
    if crit_mad, ii = find(r_aux==max(r_aux));
    else         ii = find(r_gm==max(r_gm));
    end
    
    % print best values
    for i=1:length(ii)
        fprintf('\n> hidden, gm, mad\t%d\t%4.2f\t%4.2f\n',...
                hidden(ii(i)), r_gm(ii(i)),r_mad(ii(i)))
    end

    time = com.time_tick(time,0);

    bidx = ii(1);
        
    % com.write_train_info(tabfile, dataset, featset, selfname, ...
    %                  hidden(bidx), 0, cv_res(bidx));

    %%% test best-performing parameters %%%

    fprintf('#\n+ test\n+ hidden\t%d\n', hidden(bidx))

    res = com.run_tests(data,featset,randseed,selfname,hidden(bidx),0);

    % com.write_test_info(tabfile, dataset, featset, selfname, ...
    %                     hidden(bidx), 0, res);
        
    com.print_test_info(res);
    com.time_tick(time,0);
    
end