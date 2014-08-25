function gridsearch ( dataset, featset, kernel, randseed, tabfile, data )

    cached_data = true;
    if nargin < 6, cached_data = false; end
    if nargin < 5, tabfile = 'resultsv3.tsv'; end
    if nargin < 4, randseed = [1135 223626 353 5341]; end
    com = common;
    features = com.fidx{featset};
    % find if rbf kernel is selected
    rbf = false;
    if strncmpi(kernel,'rbf',3); rbf = true;
    else assert(strncmpi(kernel,'lin',3), ...
        '! fatal error: unknown kernel function specified.');
    end

    % number of random seeds
    Nrs = length(randseed);

    % number of partitions
    Np = 5;

    % number of grid refinements
    Ngr = 4;

    % percent best values to try after each grid refine
    thr = 0.9;

    % initial grid parameters
    sig0 = 0;
    if rbf; sig0 = [-15:2:15]; end
    box0 = [-4:2:14];

    % file where to save tabulated train/test data
    % tabfile = 'resultsv3.tsv';

    fprintf('#\n> begin\t\tsvm-%s\n#\n',kernel);

    time = com.time_init();

    % initial grid
    grid = zeros(length(sig0),length(box0),3);
    % boxconstraint C
    grid(:,:,2) = ones(length(sig0),length(box0))*diag(box0);
    % rbf parameter sigma
    grid(:,:,3) = diag(sig0)*ones(length(sig0),length(box0));

    %%% Load data %%%

    if ~ cached_data
        data = struct();
        for i=1:Nrs
            [ data(i).train data(i).test] = load_data( dataset, randseed(i));
            % generate CV partitions
            [data(i).tr_real data(i).cv_real] = ...
                stpart(randseed(i), data(i).train.real, Np);
            [data(i).tr_pseudo data(i).cv_pseudo] = ...
                stpart(randseed(i), data(i).train.pseudo, Np);
        end
    end

    %%% timing and output %%%

    time = com.time_tick(time, 0);
    com.write_init(tabfile);
    com.print_train_info(dataset, featset, data);

    %%% create matlab pool %%%

    com.init_matlabpool();

    %%% grid-search %%%

    % mark all values as never tested
    tested = zeros(size(grid(:,:,1)));
    masked = zeros(size(grid(:,:,1)));

    for g = 1:Ngr

        p_sig = grid(:,:,3);
        p_box = grid(:,:,2);

        g_res = grid(:,:,1);
        g_res( find(1-[tested|masked]) ) = 0;

        fprintf('#\n> grid detail\t%g\n> parameters\t%d\n', ...
                pow2(-g+2), numel(find(1-[tested|masked])));

        for s = 1:Nrs % random seeds
            for p = 1:Np %partitions

                train = com.shuffle([data(s).train.real(  data(s).tr_real( :,p),:); ...
                                    data(s).train.pseudo(data(s).tr_pseudo(:,p),:)] );

                test_real   = data(s).train.real(  data(s).cv_real(  :,p),:);
                test_pseudo = data(s).train.pseudo(data(s).cv_pseudo(:,p),:);

                % parfor auxilliaries
                pf_idx = find(1-[floor(tested) | masked])';
                pf_res = zeros(size(pf_idx));
                pf_tst = zeros(size(pf_idx));
                pf_msk = zeros(size(pf_idx));

                parfor k = 1:length(pf_idx)
                    n = pf_idx(k);
                    Gm = 0;
                    try
                        model = struct();

                        if rbf
                            model = svmtrain(train(:,features),train(:,67), ...
                                         'Kernel_Function','rbf', ...
                                         'rbf_sigma',pow2(p_sig(n)), ...
                                         'boxconstraint',pow2(p_box(n)));
                        else
                            model = svmtrain(train(:,features),train(:,67), ...
                                         'Kernel_Function','linear', ...
                                         'boxconstraint',pow2(p_box(n)));
                        end

                        res_r = round(svmclassify(model, test_real(:,features)));
                        res_p = round(svmclassify(model, test_pseudo(:,features)));

                        Se = mean( res_r == 1 );
                        Sp = mean( res_p == -1 );
                        Gm = geomean( [Se Sp] )

                        % save Gm to results array
                        pf_res(k) = Gm;
                        pf_tst(k) = pf_tst(k)+1/(Np*Nrs);
                    catch e
                        % ignore this paramset if it does not converge
                        if strfind(e.identifier,'NoConvergence')
                            pf_tst(k) = 1;
                            pf_msk(k) = 1;
                            pf_res(k) = 0;
                        elseif strfind(e.identifier,'InvalidInput')
                            pf_tst(k) = 1;
                            pf_msk(k) = 1;
                            pf_res(k) = 0;
                        else
                            fprintf('! fatal: %s / %s', e.identifier, e.message)
                        end
                    end % try
                end % parfor k

                tested(pf_idx) = pf_tst;
                masked(pf_idx) = pf_msk;

                % @TODO fix need to transpose pf_res when using linear kernel
                if rbf
                    g_res(pf_idx) = g_res(pf_idx) + pf_res/(Np*Nrs);
                else
                    g_res(pf_idx) = g_res(pf_idx) + pf_res'/(Np*Nrs);
                end

                fprintf('.')

            end % for p
        end % for s

        [ii jj] = ind2sub(size(g_res),find(g_res==max(max(g_res))));
        for i=1:length(ii)
            fprintf('\n> gm, c, sigma\t%8.6f\t%4.2f\t%4.2f\n',...
                    g_res(ii(i),jj(i),1), grid(ii(i),jj(i),2),grid(ii(i),jj(i),3))
        end
        time = com.time_tick(time, numel(find(tested&~masked)));

        % save average partition-randseed into the grid
        grid(:,:,1) = g_res;

        % if not on last iteration
        if g < Ngr
            % interpolate grid
            [grid aux] = gridinterp(grid);
            % mark already tested values
            tested = [gridinterp(tested) & 1-aux]*1;
        end

        % mask worst values to avoid testing
        aux = grid(:,:,1);
        [zz idx]  = sort(aux(1:numel(aux)));
        masked = zeros(size(aux));
        % mask values below <thr>% of best results
        masked(idx(1:round(thr*numel(aux)))) = 1;

        % also mask non-absolute best results
        masked = masked | [ abs( aux-max(max(aux)) ) > 2/4^(g+2) ];

        if g < Ngr
            if sum(sum([masked|tested]*1)) == prod(size(masked))
                fprintf(['#\n# aborting grid search at precision %8.4f, ' ...
                         'convergence reached:\n'], pow2(-g+2))
                fprintf('# break criteria: no new params with Gm = +-%7.4f.\n', ...
                        2/4^(g+2))
                break
            end
        end
    end

    r_gm  = grid(:,:,1);
    p_sig = grid(:,:,3);
    p_box = grid(:,:,2);
    b_idx = find(r_gm==max(max(r_gm)),1,'first');

    com.write_train_info(tabfile, dataset, featset, ['svm-' kernel(1:3)], ...
                         p_box(b_idx), p_sig(b_idx), r_gm(b_idx));

    %%% test best-performing parameters %%%

    fprintf('#\n+ test\n+ boxconstraint\t%4.2f\n+ rbf_sigma\t%4.2f\n',...
             p_box(b_idx),p_sig(b_idx))

    res = com.run_tests(data,featset,randseed,kernel,p_box(b_idx),p_sig(b_idx));

    com.write_test_info(tabfile, dataset, featset, ['svm-' kernel(1:3)], ...
                         p_box(b_idx), p_sig(b_idx), res);

    com.print_test_info(res);
    com.time_tick(time,0);
end
