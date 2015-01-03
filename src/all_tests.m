function all_tests

    % load common functions
    com = common;

    % datasets, features, number of parts and random seed
    ds = { 'xue', 'ng', 'batuwita', 'ng-multi', 'batuwita-multi' };
    ft = { [1:15], [1:15], [1:15], [4 5 8], [4 5 8] };
    np = 40;
    rn = 1135;

    % time tracking and estimation
    time = com.time_init();
    tcount = 0;

    % results tsv file
    outfile = ['alltests_' com.time_string(time) '.tsv'];


    fprintf('\n>>>>> Running all single- and multi-loop tests ...\n')

    for j=1:5

        % load data
        fprintf('\n>>>>> loading data ...\n')
        svm_data = struct();
        mlp_data = struct();
        bal_data = struct();
        [ svm_data.train svm_data.test] = load_data( ds{j}, rn);
        [ mlp_data.train mlp_data.test] = load_data( ds{j}, rn, false);
        [ bal_data.train bal_data.test] = load_data( ds{j}, rn, false);

        % perform tests for each feature set
        for i=ft{j}

            fprintf('\n>>>>>>>> dataset %s, featset %d ....\n', ds{j}, i)

            % mlp unbalanced and balanced
            mlp(ds{j},i,0,np,outfile,mlp_data)
            mlp(ds{j},i,1,np,outfile,bal_data)

            % svm rbf and linear grid search
            gridsearch(ds{j},i,'linear',np,outfile,svm_data,rn)
            gridsearch(ds{j},i,'rbf',np,outfile,svm_data,rn)

            % count and estimate remaining time
            tcount = tcount + 1;
            time = com.time_tick(time,tcount);
            com.time_estimate(time,51);
        end
    end

    fprintf('\n>>>>>>>> done!!!\n')
    time = com.time_tick(time,0);
    time = com.time_tick(time,0);
    time = com.time_tick(time,0);
end

