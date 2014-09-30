function c = common

    % pick and shuffle mini-functions
    c.pick      = @(x,n) x(randsample(size(x,1),min(size(x,1),n)),:);
    c.shuffle   = @(x)   x(randsample(size(x,1),size(x,1)),:);
    c.stpick    = @(s,x,n) x(strandsample(s,size(x,1),min(size(x,1),n)),:);
    c.stshuffle = @(s,x)   x(strandsample(s,size(x,1),size(x,1)),:);

    % featureset indexes
    fidx = { 1:66; 1:32; 33:36; 37:59; 60:66; 1:36; [1:36 60:66]; ...
             37:66; 1:59; 33:66; [33:36 60:66]; 33:59; [1:32 60:66]; ...
             [1:32 37:59]; [1:32 37:66] };
    c.fidx = fidx;

    % featureset names
    fname = {'all-features', 'triplet', 'triplet-extra', 'sequence', ...
             'structure', 'triplet+extra', 'not-sequence', 'seq+struct', ...
             'not-structure', 'not-triplet', 'extra+str', 'extra+sequence', ...
             'triplet+structure', 'triplet+sequence', 'not-extra' };
    c.fname = fname;

    % write output file headers
    c.write_init = @write_init;
    function write_init(filename)
        if ~exist( filename )
            fid = fopen( filename, 'a' );
            fprintf(fid, '#%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', ...
                    'dsetup', 'class', 'dataset', 'featset', ...
                    'classifier', 'param1', 'param2', 'P');
            fclose(fid);
        end
    end

    % write train information to output file
    c.write_train_info = @write_train_info;
    function write_train_info(file,setup,fset,kern,param1,param2,result)
        fid = fopen( file, 'a' );
        fprintf(fid, '%s\t%d\t%s\t%d\t%s\t%9.8g\t%9.8g\t%9.8g\n', ...
                setup, 0, 'train', fset, kern, param1, param2, result );
        fclose(fid);
    end

    % write test information to output file
    c.write_test_info = @write_test_info;
    function write_test_info(file,setup,fset,kern,param1,param2,test_info)
        fid = fopen( file, 'a' );
        for i=1:length(test_info)
            fprintf(fid, '%s\t%d\t%s\t%d\t%s\t%9.8g\t%9.8g\t%9.8g\n', ...
                    setup, test_info(i).class, test_info(i).name, fset, ...
                    kern, param1, param2, test_info(i).rate );
        end
        fclose(fid);
    end

    % print training information to screen
    c.print_train_info = @print_train_info;
    function print_train_info(dset, fset, data)
        fprintf('> dataset\t%s\n', dset );
        fprintf('> featureset\t%s\n', fname{fset} );
        if isfield(data,'bootstrap')
            fprintf(['> partitions\tbootstrap\n#\n', ...
                     '# dataset\tsize\t#train\t#test\n', ...
                     '# -------\t----\t------\t-----\n', ...
                     '> real\t\t%d\t%d\t%d\n', ...
                     '> pseudo\t%d\t%d\t%d\n#\n' ], ...
                    size(data.b_real,1),data.b_real_size, ...
                    size(data.b_real,1)-data.b_real_size, ...
                    size(data.b_pseudo,1),data.b_pseudo_size, ...
                    size(data.b_pseudo,1)-data.b_pseudo_size);
        else
            fprintf(['> partitions\t%d\n#\n', ...
                 '# dataset\tsize\t#train\t#test\n', ...
                 '# -------\t----\t------\t-----\n', ...
                 '> real\t\t%d\t%d\t%d\n', ...
                 '> pseudo\t%d\t%d\t%d\n#\n' ], ...
                size(data(1).cv_real,  2), ...
                size(data(1).real,     1), ...
                size(data(1).tr_real,  1), ...
                size(data(1).cv_real,   1), ...
                size(data(1).pseudo,   1), ...
                size(data(1).tr_pseudo,1), ...
                size(data(1).cv_pseudo, 1));
        end
    end

    % print testing information to screen
    c.print_test_info = @print_test_info;
    function print_test_info(test_info)
        fprintf('# \t\tdataset\t\tclass\tsize\tperformance\n');
        fprintf('# \t\t-------\t\t-----\t----\t-----------\n');
        for i=1:length(test_info)
            fprintf('+ %24s\t%d\t%d\t%8.6f\n',...
                    test_info(i).name, test_info(i).class, ...
                    test_info(i).size, test_info(i).rate);
        end
    end

    % extract testing rates from test struct
    c.get_test_rates = @get_test_rates;
    function out = get_test_rates(test_info)
        out = [];
        for i=1:length(test_info)
            out = [out, test_info(i).rate];
        end
    end


    % initialize matlabpool
    c.init_matlabpool = @init_matlabpool;
    function init_matlabpool()
        Nworkers = 12;
        if matlabpool('size') == 0
            while( Nworkers > 1 )
                try
                    matlabpool(Nworkers);
                    break
                catch e
                    Nworkers = Nworkers-1;
                    fprintf(['# trying %d workers\n'], Nworkers);
            end
            end
        end
        fprintf('# using %d matlabpool workers\n', matlabpool('size'));
    end


    % perform tests
    c.run_tests = @run_tests;
    function out = run_tests(data, fset, randseed, classifier, param1, param2)

        Ntest = length(data(1).test);
        t_res = zeros(Ntest,1);
        features = fidx{fset};
        Nrep = 5;

        mlp = length(strfind(classifier,'mlp')) > 0;
        lin = length(strfind(classifier,'lin')) > 0;
        rbf = length(strfind(classifier,'rbf')) > 0;

        assert(sum([mlp lin rbf]*1) == 1, ...
               '! Fatal error: invalid classifier specified for testing.');

        out = struct();

        traindata = c.shuffle([data(1).train.real; ...
                            data(1).train.pseudo] );
        trainlabels = traindata(:,67);

        try
            if mlp
                for i=1:Nrep
                    trainlabels = [traindata(:,67) -traindata(:,67)];
                    model = patternnet( param1 );
                    model.trainFcn = 'trainscg';
                    model.trainParam.showWindow = 0;
                    model = init(model);
                    model = configure(model, traindata(:,features)', trainlabels');
                    model = train(model, traindata(:,features)', trainlabels');
                    for i=1:Ntest
                        res = sign(model(data(1).test(i).data(:,features)'))';
                        cls_results = res(:,1).*(res(:,1)~=res(:,2));
                        t_res(i) = t_res(i)+(mean( cls_results == data(1).test(i).class))/Nrep;
                    end % for i
                end
            else
                if rbf
                    model = svmtrain(traindata(:,features),trainlabels, ...
                                     'Kernel_Function','rbf', ...
                                     'rbf_sigma',pow2(param2), ...
                                     'boxconstraint',pow2(param1));
                elseif lin
                    model = svmtrain(traindata(:,features),trainlabels, ...
                                     'Kernel_Function','linear', ...
                                     'boxconstraint',pow2(param1));
                end

                for i=1:Ntest
                    cls_results = round(svmclassify(model, data(1).test(i).data(:,features)));
                    t_res(i) = t_res(i)+(mean( cls_results == data(1).test(i).class));
                end
            end

        catch e
        end % try

        for i=1:Ntest
            out(i).name = data(1).test(i).name;
            out(i).class = data(1).test(i).class;
            out(i).size = size(data(1).test(i).data,1);
            out(i).rate = t_res(i);
        end
    end

    c.time_init = @time_init;
    function out = time_init()
        out.begintime = clock;
        out.time = 0;
        out.count = 0;
    end

    c.time_tick = @time_tick;
    function out = time_tick(in,count)
        out.begintime = in.begintime;
        out.count = count;
        out.time  = round(etime(clock,in.begintime));
        fprintf( '> time\t\t%02d:%02d\n', floor(out.time/60), mod(out.time,60))
    end

    c.time_estimate = @time_estimate;
    function time_estimate(in,count)
        if in.count < 1; return; end
        esttime = round(in.time/in.count * count);
        estendt = datevec(datenum(0,0,0,0,0,esttime)+now);
        fprintf('# estimated\t%dm %d\tendtime\t%02d:%02d\n', ...
                floor(esttime/60), mod(esttime,60), fix(estendt(4:5)))
    end

    c.time_string = @time_string;
    function out = time_string(time)
        out = datestr(time.begintime,'yyyy-mm-dd_HH.MM.SS');
    end
end
