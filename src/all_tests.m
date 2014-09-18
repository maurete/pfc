function all_tests

    ds = { 'ng-multi', 'batuwita-multi', 'xue', 'ng', 'batuwita'};
    rn = [1135 223626 353 5341 657];

    Np = 20;

    com = common;
    time = com.time_init();

    outfile = ['alltests_' com.time_string(time) '.tsv'];

    fprintf('\n>>>>> Running all single-loop tests ...\n')
    for j=3:5
        fprintf('\n>>>>> loading data ...\n')
        svm_data = struct();
        mlp_data = struct();
        bal_data = struct();
        for i=1:length(rn)
            [ svm_data(i).train svm_data(i).test] = load_data( ds{j}, rn(i));
            [svm_data(i).tr_real svm_data(i).cv_real] = ...
                stpart(rn(i), svm_data(i).train.real, Np, 0.2);
            [svm_data(i).tr_pseudo svm_data(i).cv_pseudo] = ...
                stpart(rn(i), svm_data(i).train.pseudo, Np, 0.2);

            [ mlp_data(i).train mlp_data(i).test] = load_data( ds{j}, rn(i), false);
            [mlp_data(i).tr_real mlp_data(i).cv_real] = ...
                stpart(rn(i), mlp_data(i).train.real, Np, 0.2);
            [mlp_data(i).tr_pseudo mlp_data(i).cv_pseudo] = ...
                stpart(rn(i), mlp_data(i).train.pseudo, Np, 0.2);

            [ bal_data(i).train bal_data(i).test] = load_data( ds{j}, rn(i), false);
            bal_data(i).train.pseudo = ...
                com.stpick(rn(i), bal_data(i).train.pseudo, size(bal_data(i).train.real,1));
            [bal_data(i).tr_real bal_data(i).cv_real] = ...
                stpart(rn(i), bal_data(i).train.real, Np, 0.2);
            [bal_data(i).tr_pseudo bal_data(i).cv_pseudo] = ...
                stpart(rn(i), bal_data(i).train.pseudo, Np, 0.2);
        end
        time = com.time_tick(time,0);
        for i=1:15
            fprintf('\n>>>>>>>> dataset %s, featset %d ....\n', ds{j}, i)
            gridsearch(ds{j},i,'linear',rn,outfile,svm_data)
            gridsearch(ds{j},i,'rbf',rn,outfile,svm_data)
            mlp(ds{j},i,0,rn,outfile,mlp_data)
            mlp(ds{j},i,1,rn,outfile,bal_data)
        end
    end
    time = com.time_tick(time,0);
    fprintf('\n>>>>> Running all multi-loop tests ...\n')
    for j=1:2
        fprintf('\n>>>>> loading data ...\n')
        svm_data = struct();
        mlp_data = struct();
        bal_data = struct();
        for i=1:length(rn)
            [ svm_data(i).train svm_data(i).test] = load_data( ds{j}, rn(i));
            [svm_data(i).tr_real svm_data(i).cv_real] = ...
                stpart(rn(i), svm_data(i).train.real, Np, 0.2);
            [svm_data(i).tr_pseudo svm_data(i).cv_pseudo] = ...
                stpart(rn(i), svm_data(i).train.pseudo, Np, 0.2);

            [ mlp_data(i).train mlp_data(i).test] = load_data( ds{j}, rn(i), false);
            [mlp_data(i).tr_real mlp_data(i).cv_real] = ...
                stpart(rn(i), mlp_data(i).train.real, Np, 0.2);
            [mlp_data(i).tr_pseudo mlp_data(i).cv_pseudo] = ...
                stpart(rn(i), mlp_data(i).train.pseudo, Np, 0.2);

            [ bal_data(i).train bal_data(i).test] = load_data( ds{j}, rn(i), false);
            bal_data(i).train.pseudo = ...
                com.stpick(rn(i), bal_data(i).train.pseudo, size(bal_data(i).train.real,1));
            [bal_data(i).tr_real bal_data(i).cv_real] = ...
                stpart(rn(i), bal_data(i).train.real, Np, 0.2);
            [bal_data(i).tr_pseudo bal_data(i).cv_pseudo] = ...
                stpart(rn(i), bal_data(i).train.pseudo, Np, 0.2);
        end
        time = com.time_tick(time,0);
        for i=[4 5 8]
            fprintf('\n>>>>>>>> dataset %s, featset %d ....\n', ds{j}, i)
            gridsearch(ds{j},i,'linear',rn,outfile,svm_data)
            gridsearch(ds{j},i,'rbf',rn,outfile,svm_data)
            mlp(ds{j},i,0,rn,outfile,mlp_data)
            mlp(ds{j},i,1,rn,outfile,bal_data)
        end
    end
    time = com.time_tick(time,0);
    time = com.time_tick(time,0);
    time = com.time_tick(time,0);
    time = com.time_tick(time,0);
    time = com.time_tick(time,0);
end