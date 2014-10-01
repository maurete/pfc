function gridsearch ( dataset, featset, kernel, randseed, npart, crit_mad, tabfile, data )

    if nargin < 8, data = false; end
    if nargin < 7, tabfile = 'resultsv3.tsv'; end
    if nargin < 6, crit_mad = false; end
    if nargin < 5, npart = 40; end
    if nargin < 4, randseed = 1135; end

    com = common;
    features = com.fidx{featset};

    % find out if rbf kernel is selected
    rbf = false;
    if strncmpi(kernel,'rbf',3); rbf = true;
    else assert(strncmpi(kernel,'lin',3), ...
        '! fatal error: unknown kernel function specified.');
    end

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

    % number of grid refinements
    Ngr = 1;

    % initial grid parameters
    sig0 = 0;
    if rbf; sig0 = [-15:2:3]; end
    box0 = [-5:2:15];

    fprintf('#\n> begin\t\tsvm-%s\n#\n',kernel);

    time = com.time_init();

    % initial grids
    grid_gm = zeros(length(box0),length(sig0));
    grid_aux = zeros(length(box0),length(sig0));
    % boxconstraint C
    grid_box = diag(box0)*ones(length(box0),length(sig0));
    % rbf parameter sigma
    grid_sig = ones(length(box0),length(sig0))*diag(sig0);
    % mark all values as never tested
    grid_tst = zeros(size(grid_gm));
    grid_msk = zeros(size(grid_gm));

    %%% Load data %%%

    if ~ data
        data = struct();
        % if bootstrap is true, load_data loads non-partitioned data in extra b_ fields
        [data.train data.test] = load_data(dataset, randseed, false, bootstrap);

        if ~bootstrap
            % if not bootstrap (=> cv) generate CV partitions
            [data.train.tr_real data.train.cv_real] = ...
                stpart(randseed, data.train.real, Np, 0.2);
            [data.train.tr_pseudo data.train.cv_pseudo] = ...
                stpart(randseed, data.train.pseudo, Np, 0.2);
        end
    end

    %%% timing and output %%%

    time = com.time_tick(time, 0);
    com.write_init(tabfile);
    com.print_train_info(dataset, featset, data.train);

    %%% create matlab pool %%%

    com.init_matlabpool();

    %%% grid-search %%%

    for g = 1:Ngr

        % select elements to be tested
        pf_idx = find(1-[grid_tst|grid_msk]);

        % zero out elements not yet tested
        grid_gm( pf_idx ) = 0;
        grid_aux( pf_idx ) = 0;

        % emty results arrays: for each partition, will append column
        % vector with results of each parameter tested
        pf_res = [];
        pf_aux = [];

        % linearized tested, masked arrays
        pf_tst = zeros(size(pf_idx));
        pf_msk = zeros(size(pf_idx));

        fprintf('#\n> grid detail\t%g\n> parameters\t%d\n', ...
                pow2(-g+2), numel(pf_idx));

        for p = 1:Np %partitions

            if bootstrap
                % generate new bootstrap partitions
                [tr_real ts_real] = bstpart(randseed+p, size(data.train.b_real,1), ...
                                            data.train.b_real_size, 0.2);
                [tr_pseu ts_pseu] = bstpart(randseed+p, size(data.train.b_pseudo,1), ...
                                            data.train.b_pseudo_size, 0.2);

                train = com.shuffle([data.train.b_real(tr_real,:); ...
                                    data.train.b_pseudo(tr_pseu,:)] );
                test_real   = data.train.b_real(  ts_real,:);
                test_pseudo = data.train.b_pseudo(ts_pseu,:);
            else
                % select Pth crossval partition
                train = com.shuffle([data.train.real(  data.train.tr_real( :,p),:); ...
                                    data.train.pseudo(data.train.tr_pseudo(:,p),:)] );
                test_real   = data.train.real(  data.train.cv_real(  :,p),:);
                test_pseudo = data.train.pseudo(data.train.cv_pseudo(:,p),:);
            end

            % append column for saving this partition results
            pf_res = [pf_res, zeros(size(pf_idx))];

            parfor k = 1:length(pf_idx)
                % ignore if masked
                if pf_msk(k) > 0, continue, end

                n = pf_idx(k);
                Gm = 0;
                try
                    model = struct();
                    if rbf
                        % train RBF with current part, Nth param
                        model = svmtrain(train(:,features),train(:,67), ...
                                         'Kernel_Function','rbf', ...
                                         'rbf_sigma',pow2(grid_sig(n)), ...
                                         'boxconstraint',pow2(grid_box(n)));
                    else
                        % train linear with current part, Nth param
                        model = svmtrain(train(:,features),train(:,67), ...
                                         'Kernel_Function','linear', ...
                                         'boxconstraint',pow2(grid_box(n)));
                    end

                    % classify crossval/bootstrap-test set
                    res_r = round(svmclassify(model, test_real(:,features)));
                    res_p = round(svmclassify(model, test_pseudo(:,features)));
                    Se = mean( res_r == 1 );
                    Sp = mean( res_p == -1 );
                    Gm = geomean( [Se Sp] )

                    % save Gm to results array
                    pf_res(k,p) = Gm;
                    % mark as tested
                    pf_tst(k) = pf_tst(k) + 1;

                catch e
                    % ignore (mask) this paramset if it does not converge
                    if strfind(e.identifier,'NoConvergence')
                        pf_tst(k) = 1;
                        pf_msk(k) = 1;
                        pf_res(k,p) = 0;
                    elseif strfind(e.identifier,'InvalidInput')
                        pf_tst(k) = 1;
                        pf_msk(k) = 1;
                        pf_res(k,p) = 0;
                    else
                        % if some other error, print it out
                        fprintf('! fatal: %s / %s', e.identifier, e.message)
                    end
                end % try
            end % parfor k

            % save tested, masked to original grid
            grid_tst(pf_idx) = [pf_tst > 0];
            grid_msk(pf_idx) = pf_msk;

            % show some progress indicator
            fprintf('.')

            % compute aux = mean gm - mean abs deviation for results
            if p>1
                if crit_mad, pf_aux = [pf_aux, mean(pf_res,2)-mad(pf_res,0,2)];
                else,        pf_aux = [pf_aux, mean(pf_res,2)]; end
            end

            % test for convergence on bootstrap
            if bootstrap && p>10
                % assuming mad -> constant on p -> Inf,
                % pf_aux shoud converge to constant values
                area = sum(abs(pf_aux(:,p-1)-pf_aux(:,p-2)));
                if area < 0.001*size(pf_aux,1)
                    % break if each paramset on avg varies less than 0.1%
                    break;
                else
                    fprintf(' %4.4f ', area/length(pf_aux))
                end
            end
        end % for p

        % save mean res, aux back into grid
        grid_gm(pf_idx) = mean(pf_res,2);
        grid_aux(pf_idx) = pf_aux(:,end);

        % plot pf_aux convergence
        plot(1:length(pf_idx),pf_aux)

        % select best values
        if crit_mad, [ii jj] = find(grid_aux==max(max(grid_aux)));
        else         [ii jj] = find(grid_gm==max(max(grid_gm)));
        end

        % print best values
        for i=1:length(ii)
            fprintf('\n> gm, c, sigma\t%8.6f\t%4.2f\t%4.2f\n',...
                    grid_gm(ii(i),jj(i)), grid_box(ii(i),jj(i)),grid_sig(ii(i),jj(i)))
        end

        time = com.time_tick(time, numel(find(grid_tst&~grid_msk)));


        %%%%%%%%%%%%%%%% ZOOM GRID REFINE

        if false && g < Ngr
            % concatenate all grids into one
            grid = cat(3, grid_gm, grid_aux, grid_box, grid_sig, grid_tst, grid_msk);

            % find 'zoom region' with best rates
            if crit_mad, [ii jj] = gridzoom(grid(:,:,2));
            else [ii jj] = gridzoom(grid(:,:,1));
            end

            % select sub-grid
            grid = grid(ii,jj,:);
            % interpolate grid
            [grid tst] = gridinterp(grid);

            % restore test and mask grids
            grid_tst = [grid(:,:,5) & 1-tst]*1;
            grid_msk = floor(grid(:,:,6));

            % rebuild grids for next refinement iteration
            grid_gm = grid(:,:,1);
            grid_aux = grid(:,:,2);

            % parameter grids
            grid_box = grid(:,:,3);
            grid_sig = grid(:,:,4);

            %continue;

        end % if g < Ngr

        %%%%%%%%%%%%%% THRESHOLD GRID REFINE

        % if not on last iteration
        if g < Ngr

            %%% threshold value
            thr = 0.9;

            % concatenate all grids into one
            grid = cat(3, grid_gm, grid_aux, grid_box, grid_sig, grid_tst, grid_msk);

            % interpolate grid
            [grid tst] = gridinterp(grid);

            % restore test and mask grids
            grid_tst = [grid(:,:,5) & 1-tst]*1;
            grid_msk = floor(grid(:,:,6));

            % rebuild grids for next refinement iteration
            grid_gm = grid(:,:,1);
            grid_aux = grid(:,:,2);

            % parameter grids
            grid_box = grid(:,:,3);
            grid_sig = grid(:,:,4);

            % mask values below threshold
            if crit_mad, [zz idx]  = sort(grid_aux(1:numel(grid_aux)));
            else [zz idx]  = sort(grid_gm(1:numel(grid_gm)));
            end
            grid_msk(idx(1:max(round(thr*numel(grid_msk)),numel(grid_msk)-200))) = 1;

        end % if g < Ngr

    end % for g

    % find final best result after grid refinement
    if crit_mad
        b_idx = find(grid_aux==max(max(grid_aux)),1,'first');
    else
        b_idx = find(grid_gm==max(max(grid_gm)),1,'first');
    end

    com.write_train_info(tabfile, dataset, featset, ['svm-' kernel(1:3)], ...
                         grid_box(b_idx), grid_sig(b_idx), grid_gm(b_idx));

    %%% test best-performing parameters %%%

    fprintf('#\n+ test\n+ boxconstraint\t%4.2f\n+ rbf_sigma\t%4.2f\n',...
             grid_box(b_idx),grid_sig(b_idx))

    res = com.run_tests(data,featset,randseed,kernel,grid_box(b_idx),grid_sig(b_idx));

    com.write_test_info(tabfile, dataset, featset, ['svm-' kernel(1:3)], ...
                         grid_box(b_idx), grid_sig(b_idx), res);

    com.print_test_info(res);
    com.time_tick(time,0);
end
