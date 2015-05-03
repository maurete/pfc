function results = test_mlp_cvparts(lib, seed)

    gtime = time_init();
    init_matlabpool;

    ds = { 'xue', 'ng-multi', 'batuwita-multi' };
    ft = { [1:6 8], [4 5 8], [4 5 8] };
    cv = [ 10 ];

    fann = false;
    if strcmpi(lib,'fann'), fann = true; end

    results = {};
    filename = sprintf('res-mlpcv-%s-%d-%s',lib,seed,...
                       datestr(now(),'yyyymmdd.HH.MM.SS'));

    i = 0;
    for d = 1:length(ds)
        for f = 1:length(ft{d})
            fprintf('\n\n# dataset %s featset %d\n\n', ds{d},ft{d}(f))

            for p = 1:numel(cv)
                problem = problem_gen( ds{d}, 'CVPartitions', cv(p), ...
                                       'CVRatio', max([0.1,1/cv(p)]), ...
                                       'Balanced', seed);

                fprintf('\n# %d partitions\n', cv(p))
                i = i+1;
                time = time_init();

                [params,rh,rr,rn,res] = select_model_mlp(problem,ft{d}(f),[],[],[],false,fann);

                time = time_tick(time,1);
                gtime = time_tick(gtime,1);
                time_estimate(gtime,13*numel(cv));

                results(i,:) = { ...
                    ds{d}, ... % dataset
                    ft{d}(f), ... % feature set
                    sprintf('mlpcv%d',cv(p)), ... % method name
                    time.time, ... % time finding model parameters
                    0, ... % number of trainings
                    res(1).se, ... % SE for same-source-as-train datasets
                    res(1).sp, ... % SP
                    res(1).gm, ... % geomean
                    0, ... % SE for other-source datasets
                    0, ... % SP
                    0, ... % geomean
                    params, ... % best parameters found
                    res, ... % test results
                    {rh,rr,rn} ... % nothing
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
