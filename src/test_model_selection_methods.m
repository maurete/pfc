function results = test_model_selection_methods( lib, kernel, npart, ratio, seed)

    gtime = time_init();

    ds = { 'xue', 'ng-multi', 'batuwita-multi' };
    ft = { [1:6 8], [4 5 8], [4 5 8] };

    init_matlabpool;

    results = {};

    linear = get_kernel(kernel,'linear',false);

    filename = sprintf('res-ms-%s-%s-%d-%.1f-%d-%s',lib,kernel,npart,ratio,seed,...
                       datestr(now(),'yyyymmdd.HH.MM.SS'));

    i = 0;
    for d = 1:length(ds)
        for f = 1:length(ft{d})
            fprintf('\n\n# dataset %s featset %d\n\n', ds{d},ft{d}(f))
            problem = problem_load(ds{d},ft{d}(f),npart,ratio,seed,[],[],false);

            % Trivial model selection
            fprintf('\n# trivial\n')
            i = i+1;
            time = time_init();

            [params,res] = select_model_trivial(problem,kernel,lib);

            time = time_tick(time,1);
            gtime = time_tick(gtime,1);
            time_estimate(gtime,(4-linear)*21);

            results(i,:) = { ...
                ds{d}, ... % dataset
                ft{d}(f), ... % feature set
                'trivial', ... % method name
                time.time, ... % time finding model parameters
                0, ... % number of trainings
                res(1).sen_source, ... % SE for same-source-as-train datasets
                res(1).spe_source, ... % SP
                geomean([res(1).sen_source, res(1).spe_source]), ... % geomean
                res(1).sen_other, ... % SE for other-source datasets
                res(1).spe_other, ... % SP
                geomean([res(1).sen_other, res(1).spe_other]), ... % geomean
                params, ... % best parameters found
                res, ... % test results
                [] ... % nothing
                           };


            % Grid search
            fprintf('\n# gridsearch\n')
            i = i+1;
            time = time_init();

            [params,grid,res,ntr] = select_model_gridsearch( ...
                problem,kernel,lib, ...
                2, ... % number of iterations
                'gm', ... % criterion
                'threshold', ... % strategy
                [],[], ... % ignore
                true ... % fast: dont calculate rmb, empirical error
                );

            time = time_tick(time,1);
            gtime = time_tick(gtime,1);
            time_estimate(gtime,(4-linear)*21);

            results(i,:) = { ...
                ds{d}, ... % dataset
                ft{d}(f), ... % feature set
                'gridsearch', ... % method name
                time.time, ... % time finding model parameters
                ntr, ... % number of trainings
                res(1).sen_source, ... % SE for same-source-as-train datasets
                res(1).spe_source, ... % SP
                geomean([res(1).sen_source, res(1).spe_source]), ... % geomean
                res(1).sen_other, ... % SE for other-source datasets
                res(1).spe_other, ... % SP
                geomean([res(1).sen_other, res(1).spe_other]), ... % geomean
                params, ... % best parameters found
                res, ... % test results
                grid ... % grid
                           };


            % Empirical
            fprintf('\n# empirical\n')
            i = i+1;
            time = time_init();

            [params,ph,eh,res,ntr] = select_model_empirical(problem,kernel,lib);

            time = time_tick(time,1);
            gtime = time_tick(gtime,1);
            time_estimate(gtime,(4-linear)*21);

            results(i,:) = { ...
                ds{d}, ... % dataset
                ft{d}(f), ... % feature set
                'empirical', ... % method name
                time.time, ... % time finding model parameters
                ntr, ... % number of trainings
                res(1).sen_source, ... % SE for same-source-as-train datasets
                res(1).spe_source, ... % SP
                geomean([res(1).sen_source, res(1).spe_source]), ... % geomean
                res(1).sen_other, ... % SE for other-source datasets
                res(1).spe_other, ... % SP
                geomean([res(1).sen_other, res(1).spe_other]), ... % geomean
                params, ... % best parameters found
                res, ... % test results
                {ph,eh} ... % param history, error history
                           };


            % RMB
            if ~linear % dont test rmb if linear kernel
                fprintf('\n# rmb\n')
                i = i+1;
                time = time_init();

                [params,ph,eh,res,ntr] = select_model_rmb(problem,kernel,lib);

                time = time_tick(time,1);
                gtime = time_tick(gtime,1);
                time_estimate(gtime,84);

                results(i,:) = { ...
                    ds{d}, ... % dataset
                    ft{d}(f), ... % feature set
                    'rmb', ... % method name
                    time.time, ... % time finding model parameters
                    ntr, ... % number of trainings
                    res(1).sen_source, ... % SE for same-source-as-train datasets
                    res(1).spe_source, ... % SP
                    geomean([res(1).sen_source, res(1).spe_source]), ... % geomean
                    res(1).sen_other, ... % SE for other-source datasets
                    res(1).spe_other, ... % SP
                    geomean([res(1).sen_other, res(1).spe_other]), ... % geomean
                    params, ... % best parameters found
                    res, ... % test results
                    {ph,eh} ... % param history, error history
                               };
            end


            % Show and save partial results
            fid = fopen([filename '.csv'],'w');
            fprintf('\nResults:\n')
            sstr = ['%16s,%3d,%11s,%4d,%4d,%5.2f,%5.2f,%5.2f,%5.2f,%5.2f,%5.2f' ...
                    repmat(',%7.3f',1,numel(results{1,12})) '\n'];
            fstr = ['%s,%d,%s,%d,%d,%f,%f,%f,%f,%f,%f' ...
                    repmat(',%f',1,numel(results{1,12})) '\n'];

            for j=1:i
                fprintf(fid,fstr,results{j,1:11},results{j,12});
                fprintf(sstr,results{j,1:11},results{j,12});
            end
            fclose(fid);

            save([filename '.mat'],'results');

        end
    end
end
