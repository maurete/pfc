function svm_lin ( dataset, featset, random_seeds )

    if nargin < 3, random_seeds = [303456; 456789; 5829]; end

    % aux functions
    pick      = @(x,n) x(randsample(size(x,1),min(size(x,1),n)),:);
    shuffle   = @(x)   x(randsample(size(x,1),size(x,1)),:);
    stpick    = @(i,x,n) x(strandsample(random_seeds(i),size(x,1),min(size(x,1),n)),:);
    stshuffle = @(i,x)   x(strandsample(random_seeds(i),size(x,1),size(x,1)),:);
    function o=zerofill(i);o=0;if i;o=i;end;end;

    % featureset indexes
    fidx = { 1:66; 1:32; 33:36; 37:59; 60:66; 1:36; [1:36 60:66]; ...
             37:66; 1:59; 33:66; [33:36 60:66]; 33:59; [1:32 60:66]; ...
             [1:32 37:59]; [1:32 37:66] };
    fname = {'all-features', 'triplet', 'triplet-extra', 'sequence', ...
             'structure', 'triplet+extra', 'not-sequence', ...
             'seq+struct', 'not-structure', 'not-triplet', 'extra+str', ...
             'extra+sequence', 'triplet+structure', 'triplet+sequence', ...
             'not-extra' };
    features = fidx{featset};

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    fprintf('#\n> begin svm-linear\n#\n');

    % keep record of this experiment for review
    S = struct();
    S.random_seeds = random_seeds;
    S.featureset = featset;
    S.partitions = 5;
    S.gridsearch = 4;
    S.initial_boxconstraint = exp([-4:2:14]);
    S.begintime = clock;
    S.time = 0;
    S.numcv = 0;

    S.data = struct();
    for i=1:length(S.random_seeds)
        [ S.data(i).train S.data(i).test] = load_data( dataset, S.random_seeds(i));
        % generate CV partitions
        [S.data(i).cv_train_real S.data(i).cv_test_real] = ...
            stpart(S.random_seeds(i), S.data(i).train.real, S.partitions);
        [S.data(i).cv_train_pseudo S.data(i).cv_test_pseudo] = ...
            stpart(S.random_seeds(i), S.data(i).train.pseudo, S.partitions);
    end

    % file where to save tabulated train/test data
    tabfile = 'resultsv2.tsv'
    if ~exist( tabfile )
        fid = fopen( tabfile, 'a' );
        fprintf( fid, [ '#dsetup\tclass\tdataset\tfeatset\t' ...
                        'classifier\tparam1\tparam2\tP\n' ] );
        fclose(fid);
    end
    function writetab(fid,cls,dset,param,result)
        fprintf(fid, '%s\t%d\t%s\t%d\t%s\t%9.8g\t%9.8g\t%9.8g\n', ...
                dataset, cls, dset, featset, 'svm-linear', param, [], result );
    end

    fprintf('> dataset\t%s\n', dataset );
    fprintf('> featureset\t%s\n', fname{featset} );
    fprintf([ '# begin cross-validation training\n> partitions\t%d\n#\n', ...
              '# dataset\tsize\t#train\t#test\n', ...
              '# -------\t----\t------\t-----\n', ...
              '> real\t\t%d\t%d\t%d\n', ...
              '> pseudo\t%d\t%d\t%d\n#\n' ], ...
            S.partitions, ...
            size(S.data(1).train.real,     1), ...
            size(S.data(1).cv_train_real,  1), ...
            size(S.data(1).cv_test_real,   1), ...
            size(S.data(1).train.pseudo,   1), ...
            size(S.data(1).cv_train_pseudo,1), ...
            size(S.data(1).cv_test_pseudo, 1));

    % create matlab pool
    num_workers = 12;
    if matlabpool('size') == 0
        while( num_workers > 1 )
            try
                matlabpool(num_workers);
                break
            catch e
                num_workers = num_workers-1;
                fprintf(['# trying %d workers\n'], num_workers);
            end
        end
    end
    fprintf('# using %d matlabpool workers\n', matlabpool('size'));

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Grid-search

    GS = struct();
    % initial boxconstraint values for grid search
    GS(1).boxconstraint = S.initial_boxconstraint;

    % refine sigma-bc
    for r=1:S.gridsearch
        fprintf('#\n> gridsearch\t%d\n> parameters\t%d\n', ...
                r, length(GS(r).boxconstraint))
        if r>1
            esttime = round(S.time/S.numcv*length(GS(r).boxconstraint));
            estendt = datevec(datenum(0,0,0,0,0,esttime)+now);
            fprintf('# estimated\t%dm %d\tendtime\t%02d:%02d\n', ...
                    floor(esttime/60), mod(esttime,60), fix(estendt(4:5)))
        end

        N = length(GS(r).boxconstraint);
        RS = length(S.random_seeds);
        T = S.partitions;

        % results for current r
        res = zeros(N,RS,T);
        % ignore flag, avoid trying nonconvergent values
        ignore = zeros(size(GS(r).boxconstraint));
        % details for random partition
        GS(r).rand = struct();

        for rs = 1:RS
            train_real        = S.data(rs).train.real;
            train_pseudo      = S.data(rs).train.pseudo;
            part_train_real   = S.data(rs).cv_train_real;
            part_train_pseudo = S.data(rs).cv_train_pseudo;
            part_test_real    = S.data(rs).cv_test_real;
            part_test_pseudo  = S.data(rs).cv_test_pseudo;

            % details for each iteration
            GS(r).rand(rs).iter = struct();

            for t=1:T
                % shuffle data and separate labels
                train = shuffle( [  train_real(    part_train_real(:,mod(t,T)+1),:); ...
                                    train_pseudo(part_train_pseudo(:,mod(t,T)+1),:)] );
                GS(r).rand(rs).iter(t).train_ids  = train(:,68:70);
                train_lbls                        = train(:,67);
                GS(r).rand(rs).iter(t).train_lbls = train_lbls;
                train                             = train(:,1:66);

                test_real   =   train_real(  part_test_real(:,mod(t,T)+1),1:66);
                test_pseudo = train_pseudo(part_test_pseudo(:,mod(t,T)+1),1:66);

                GS(r).rand(rs).iter(t).test_real_ids   = ...
                    train_real(  part_test_real(:,mod(t,T)+1),68:70);
                GS(r).rand(rs).iter(t).test_pseudo_ids = ...
                    train_pseudo(part_test_pseudo(:,mod(t,T)+1),68:70);

                % parallel-for each parameter setting
                parfor n=1:N
                    if ignore(n) continue; end
                    Gm = 0;
                    try
                        model = svmtrain(train(:,features),train_lbls, ...
                                         'Kernel_Function','linear', ...
                                         'boxconstraint',GS(r).boxconstraint(n));

                        res_r = round(svmclassify(model, test_real(:,features)));
                        res_p = round(svmclassify(model, test_pseudo(:,features)));

                        Se = mean( res_r == 1 );
                        Sp = mean( res_p == -1 );
                        Gm = geomean( [Se Sp] );

                        % ignore this paramset if it's too bad
                        if Gm < 0.70
                            ignore(n) = 1;
                            continue
                        end

                    catch e
                        % ignore this paramset if it does not converge
                        if strfind(e.identifier,'NoConvergence')
                            ignore(n) = 1;
                        elseif strfind(e.identifier,'InvalidInput')
                            ignore(n) = 1;
                        else
                            fprintf('! %s / %s', e.identifier, e.message)
                        end
                    end % try

                    % save Gm to results array
                    res(n,rs,t) = Gm;
                end % parfor n
            end % for t
        end % for rs

        % save avg performance
        GS(r).gm = mean(mean(res,3),2);

        % highlight best-performing paramsets
        % select values on the 80th percentile and above
        [ zzz indx ] = sort(GS(r).gm);
        best0 = zeros(size(GS(r).gm'));
        best0(indx(floor(N*0.8):end)) = 1;
        % keep only absolute best values
        best1 = [ abs(GS(r).gm-max(GS(r).gm)) < 4^(-r-2) ]';

        GS(r).best = best0 .* best1 .* (1-ignore);

        fprintf('# selected %d out of %d params as best.\n', sum(GS(r).best), N)

        if max(GS(r).gm) < 0.25
            fprintf('! no convergence, sorry\n')
            fid = fopen( tabfile, 'a' );
            writetab(fid, 0, 'train', [], 0)
            for i=1:length(S.data(1).test)
                writetab(fid, S.data(1).test(i).class, S.data(1).test(i).name, [], 0)
            end
            fclose(fid)
            return
        end

        % refine grid around central value n
        neighbor = @(n,d,w) exp([log(n)-w/2^(d-1):1/2^(d-1):log(n)+w/2^(d-1)]);

        % new parameters for next iteration
        nc = [];
        fprintf('#\n# idx\tlog(C)\t\tgeomean\n');
        fprintf(   '# ---\t------\t\t-------\n');

        % do not consider more than 50% of tests as "best"
        % brkcount = length(GS(r).best)/2;
        for d=find(GS(r).best)
            fprintf('< %d\t%8.6f\t%8.6f\n', d, log(GS(r).boxconstraint(d)), GS(r).gm(d) );
            % append new values to ns,nc
            nc = [ nc, neighbor(GS(r).boxconstraint(d), r,4) ];
            % decrease break counter
            % brkcount = brkcount-1;
            % if brkcount < 0, break; end
        end % for d

        GS(r).bestC = ( GS(r).boxconstraint(find(GS(r).best)) );

        % values for next grid refine
        if r < S.gridsearch
            GS(r+1).precision     = 1/2^(r-1); % as in neighbor function
            GS(r+1).boxconstraint = logunique( nc, 1e-5 );
        end

        S.numcv = S.numcv + length(GS(r).boxconstraint);
        S.time  = round(etime(clock,S.begintime));
        fprintf( '#\n> time\t%02d:%02d\n', floor(S.time/60), mod(S.time,60))

    end % for r

    S.GS = GS;

    % perform classification on test datasets
    bidx = find(S.GS(S.gridsearch).best,1,'first');

    % write tsv-data
    fid = fopen( tabfile, 'a' );
    writetab(fid, 0, 'train', log(S.GS(S.gridsearch).boxconstraint(bidx)), ...
             S.GS(S.gridsearch).gm(bidx))
    if max(S.GS(S.gridsearch).gm) < 0.75
        fprintf('! train CV rate too low, not testing\n')
        for i=1:length(S.data(1).test)
            writetab(fid, S.data(1).test(i).class, S.data(1).test(i).name,[],0)
        end
        fclose(fid);
        return
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    fprintf('#\n# begin testing, C=%g\n',log(S.GS(S.gridsearch).bestC(1)));
    S.test = zeros(length(S.data(rs).test), length(S.random_seeds));

    for rs=1:length(S.random_seeds)

        train_real        = S.data(rs).train.real;
        train_pseudo      = S.data(rs).train.pseudo;

        R = S.gridsearch;

        train = stshuffle(rs,[train_real;train_pseudo]);

        train_lbls = train(:,67);

        model = svmtrain(train(:,features),train_lbls, ...
                         'Kernel_Function','linear', ...
                         'boxconstraint',S.GS(R).bestC(1));

        for i=1:length(S.data(rs).test)
            cls_results = round(svmclassify(model, S.data(rs).test(i).data(:,features)));
            S.test(i,rs) = mean( cls_results == S.data(rs).test(i).class);
        end

    end % for rs

    % print and write test results
    fprintf('# \t\tdataset\t\t\tclass\tsize\tperformance\n');
    fprintf('# \t\t-------\t\t\t-----\t----\t-----------\n');
    fid = fopen( tabfile, 'a' );
    for i=1:length(S.data(1).test)
        fprintf('+ %32s\t%d\t%d\t%8.6f\n',...
                S.data(1).test(i).name, S.data(1).test(i).class, ...
                size(S.data(1).test(i).data,1), mean(S.test(i,:)));

        writetab(fid, S.data(1).test(i).class, S.data(1).test(i).name, ...
                 log(S.GS(S.gridsearch).bestC(1)),mean(S.test(i,:)))
    end
    fclose(fid);

end
