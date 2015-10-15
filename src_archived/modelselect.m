function modelselect ( dataset, featset, kernel, lib, npart, ratio, randseed, tabfile, data )

    if nargin < 9, ratio = 0.1; end
    if nargin < 8, randseed = 1135; end
    if nargin < 7, data = false; end
    if nargin < 6, tabfile = 'resultsv3.tsv'; end
    if nargin < 5, npart = 40; end

    com = common;

    % Initial arguments
    C0 = 1;
    gamma0 = 0;

    % find out if rbf kernel is selected
    % find out if which kernel is selected
    if     strncmpi(kernel,'rbf_uni',7);    kernel = 'rbf_uni';
    elseif strncmpi(kernel,'linear_uni',7); kernel = 'linear_uni';
    elseif strncmpi(kernel,'lin',3);        kernel = 'linear';
    elseif strncmpi(kernel,'rbf',4);        kernel = 'rbf';
    else error('! fatal error: unknown kernel function specified.');
    end

    % features indexes
    features = com.featindex{featset};

    %%% Load data %%%

    if ~isstruct(data)
        data = struct();
        [data.train data.test] = load_data(dataset, randseed, false);
    end

    trainset = com.stshuffle(randseed, [data.train.real;data.train.test]);
    trainlabels = trainset(:,67);

    partinfo = struct();
    [partinfo.train partinfo.validation] = stpart( ...
        randseed, trainset, npart, ratio);


    for p=1:npart

    theta0 = [C0 gamma0];



    end












    %%% timing and output %%%

    time = com.time_tick(time, 1);
    com.write_init(tabfile, true);
    com.print_train_info(dataset, featset, data.train);

    %%% create matlab pool %%%

    com.init_matlabpool();

    %%% grid-search %%%

    for g = 1:Ngr

        %linearize grid
        lgrid = gu.pack(grid);

        % select elements to be tested
        GIDX = find(1-[lgrid(:,LTST)|lgrid(:,LIGN)]);

        % zero out elements not yet tested
        lgrid( GIDX, [ LSEN LSPE LSED LSPD LGEO LMAD ] ) = 0;

        % emty results arrays: for each partition, will append column
        % vector with results of each parameter tested
        part_sen = [];
        part_spe = [];
        part_geo = [];
        part_rmb = [];

        fprintf('#\n> gridsearch  iteration\t%g\n> parameters\t%d\n', ...
                g, numel(GIDX));

        tst_aux = lgrid(GIDX,LTST);
        ign_aux = lgrid(GIDX,LIGN);
        part_rmb = zeros(size(GIDX));

        for p = 1:Np %partitions
            % select Pth crossval partition
            train = com.shuffle([data.train.real(  data.train.tr_real( :,p),:); ...
                                data.train.pseudo(data.train.tr_pseudo(:,p),:)] );
            test_real   = data.train.real(  data.train.cv_real(  :,p),:);
            test_pseudo = data.train.pseudo(data.train.cv_pseudo(:,p),:);

            % append column for saving this partition results
            part_sen = [part_sen, zeros(size(GIDX))];
            part_spe = [part_spe, zeros(size(GIDX))];
            part_geo = [part_geo, zeros(size(GIDX))];

            parfor k = 1:length(GIDX)
                n = GIDX(k);

                % ignore if masked
                if ign_aux(k) > 0, continue, end

                try
                    model = struct();
                    if isempty(strfind(kernel,'uni'))
                        % classical RBF or linear kernel selected
                        model = mysvm_train( lib, kernel, ...
                                             train(:,features), train(:,67), ...
                                             lgrid(n,LBOX), lgrid(n,LGAM), ...
                                             false, 1e-6 );
                    else
                        % unified framework RBF or linear kernel
                        model = mysvm_train( lib, kernel, ...
                                             train(:,features), train(:,67), ...
                                             1e5, [lgrid(n,LBOX), lgrid(n,LGAM)], ...
                                             false, 1e-6 );
                    end

                    % classify crossval/bootstrap-test set
                    res_r = round(mysvm_classify(model, test_real(:,features)));
                    res_p = round(mysvm_classify(model, test_pseudo(:,features)));

                    % save Gm to results array
                    part_sen(k,p) = mean( res_r == 1 );
                    part_spe(k,p) = mean( res_p == -1 );
                    part_geo(k,p) = geomean( [part_sen(k,p) part_spe(k,p)] );

                    % mark as tested
                    tst_aux(k) = tst_aux(k) + 1;

                    if p < 2
                        if strcmp(kernel,'rbf')
                            part_rmb(k,p) = RM_eval(dataset, featset, kernel, lib, ...
                                                    lgrid(n,LBOX), lgrid(n,LGAM), 1, false, ...
                                                    randseed, data);
                        end
                    end


                catch e
                    % ignore (mask) this paramset if it does not converge
                    if strfind(e.identifier,'NoConvergence')
                        ign_aux(k) = 1;
                        tst_aux(k) = 1;
                    elseif strfind(e.identifier,'InvalidInput')
                        ign_aux(k) = 1;
                        tst_aux(k) = 1;
                    else
                        % if some other error, print it out
                        fprintf('! fatal: %s / %s', e.identifier, e.message)
                    end
                end % try
            end % parfor k

            % show some progress indicator
            if mod(p,10) == 0, fprintf('|'), else fprintf('.'), end

        end % for p

        % save tested, masked to original grid
        % @TODO marking this while still inside partition testing
        lgrid(GIDX,LTST) = [ tst_aux > 0 ];
        lgrid(GIDX,LIGN) = [ ign_aux > 0 ];

        % save mean res, aux back into grid
        lgrid(GIDX,LSEN) = mean(part_sen,2);
        lgrid(GIDX,LSPE) = mean(part_spe,2);
        lgrid(GIDX,LGEO) = mean(part_geo,2);

        lgrid(GIDX,LSED) = mad(part_sen,0,2);
        lgrid(GIDX,LSPD) = mad(part_spe,0,2);
        lgrid(GIDX,LMAD) = mad(part_geo,0,2);

        lgrid(GIDX,LRMB) = part_rmb;

        [ii] = find(lgrid(:,LGEO)==max(lgrid(:,LGEO)));

        % print best values
        for i=1:length(ii)
            fprintf('\n> gm, mapc, mapgamma\t%8.6f\t%4.2f\t%4.2f\n',...
                    lgrid(ii(i),LGEO), fmap(lgrid(ii(i),LBOX)), fmap(lgrid(ii(i),LGAM)))
        end

        time = com.time_tick(time, 1);

        grid = gu.unpack(lgrid);

        if g < Ngr
            tunefunc = @gt.nbest;
            %grid = gt.nbest(grid,4,2,IGEO,[],IIGN,dmap,fmap);
            grid = gt.zoom(grid,4,IGEO,[IGEO IRMB],IIGN,dmap,fmap);
            %grid = gt.threshold(grid,0,100,IGEO,[],IIGN,dmap,fmap); % for simple interp
            %grid = gt.threshold(grid,0.9,100,IGEO,[],IIGN,dmap,fmap); % only 10th decile
        end % if g < Ngr


    end % for g

    % find final best result after grid refinement
    [ii jj] = find(grid.data(:,:,IGEO) == max(max(grid.data(:,:,IGEO))),1,'first');

    com.write_train_info(tabfile, dataset, featset, ['svm-' kernel(1:3)], ...
                         fmap(grid.param1(ii)), fmap(grid.param2(jj)), ...
                         grid.data(ii,jj,IGEO), randseed);

    %%% test best-performing parameters %%%

    fprintf('#\n+ test\n+ logc\t%4.2f\n+ loggamma\t%4.2f\n',...
             fmap(grid.param1(ii)), fmap(grid.param2(jj)))

    res = com.run_tests(data,featset,randseed,kernel,lib,grid.param1(ii), grid.param2(jj));

    com.write_test_info(tabfile, dataset, featset, ['svm-' kernel(1:3)], ...
                        fmap(grid.param1(ii)), fmap(grid.param2(jj)), res, randseed);

    com.print_test_info(res);
    com.time_tick(time,0);

end
