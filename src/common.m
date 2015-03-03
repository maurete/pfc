function c = common

    c.strandsample = @strandsample;
    function s = strandsample(seed, population, nsamples)
        a = rng(seed);
        s = randsample(population, nsamples);
        rng(a);
    end

    % pick and shuffle mini-functions
    c.pick      = @(x,n)   x(randsample(size(x,1),min(size(x,1),n)),:);
    c.shuffle   = @(x)     x(randsample(size(x,1),size(x,1)),:);
    c.stpick    = @(s,x,n) x(strandsample(s,size(x,1),min(size(x,1),n)),:);
    c.stshuffle = @(s,x)   x(strandsample(s,size(x,1),size(x,1)),:);

    % featureset indexes
    c.featindex = { 1:66; 1:32; 33:36; 37:59; 60:66; 1:36; [1:36 60:66]; ...
                    37:66; 1:59; 33:66; [33:36 60:66]; 33:59; [1:32 60:66]; ...
                    [1:32 37:59]; [1:32 37:66] };

    % featureset names
    c.featname = {'all-features', 'triplet', 'triplet-extra', 'sequence', ...
                  'structure', 'triplet+extra', 'not-sequence', 'seq+struct', ...
                  'not-structure', 'not-triplet', 'extra+str', 'extra+sequence', ...
                  'triplet+structure', 'triplet+sequence', 'not-extra' };

    % write output file headers
    c.write_init = @write_init;
    function write_init(filename, extended, varargin)
        if ~exist( filename )
            fid = fopen( filename, 'a' );
            if nargin < 2
                fprintf(fid, '#%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', ...
                        'dsetup', 'class', 'dataset', 'featset', ...
                        'classifier', 'mapparam1', 'mapparam2', 'P');
            else
                fprintf(fid, '#%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', ...
                        'dsetup', 'class', 'dataset', 'featset', ...
                        'classifier', 'mapparam1', 'mapparam2', 'P', 'randseed');
            end
            fclose(fid);
        end
    end

    % write train information to output file
    c.write_train_info = @write_train_info;
    function write_train_info(file,setup,fset,kern,param1,param2,result,seed,varargin)
        fid = fopen( file, 'a' );
        if nargin<8, fprintf(fid, '%s\t%d\t%s\t%d\t%s\t%9.8g\t%9.8g\t%9.8g\n', ...
                             setup, 0, 'train', fset, kern, param1, param2, result );
        else, fprintf(fid, '%s\t%d\t%s\t%d\t%s\t%9.8g\t%9.8g\t%9.8g\t%d\n', ...
                setup, 0, 'train', fset, kern, param1, param2, result, seed );
        end
        fclose(fid);
    end

    % write test information to output file
    c.write_test_info = @write_test_info;
    function write_test_info(file,setup,fset,kern,param1,param2,test_info, seed, varargin)
        fid = fopen( file, 'a' );
        for i=1:length(test_info)
            if nargin<8
                fprintf(fid, '%s\t%d\t%s\t%d\t%s\t%9.8g\t%9.8g\t%9.8g\n', ...
                        setup, test_info(i).class, test_info(i).name, fset, ...
                        kern, param1, param2, test_info(i).rate );
            else
                fprintf(fid, '%s\t%d\t%s\t%d\t%s\t%9.8g\t%9.8g\t%9.8g\t%d\n', ...
                        setup, test_info(i).class, test_info(i).name, fset, ...
                        kern, param1, param2, test_info(i).rate, seed );
            end
        end
        fclose(fid);
    end

    % print training information to screen
    c.print_train_info = @print_train_info;
    function print_train_info(dset, fset, data)
        fprintf('> dataset\t%s\n', dset );
        fprintf('> featureset\t%d\t%s\n', fset, c.featname{fset} );
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

    % % extract testing rates from test struct
    % c.get_test_rates = @get_test_rates;
    % function out = get_test_rates(test_info)
    %     out = [];
    %     for i=1:length(test_info)
    %         out = [out, test_info(i).rate];
    %     end
    % end

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
    function out = run_tests(data, fset, randseed, kernel, lib, C, gamma)

        Ntest = length(data(1).test);
        t_res = zeros(Ntest,1);
        features = c.featindex{fset};
        Nrep = 5;

        % find out if rbf kernel is selected
        % find out if which kernel is selected
        % if strncmpi(kernel,'rbf_uni',7);  kernel = 'rbf_uni';
        % elseif strncmpi(kernel,'lin',3);  kernel = 'linear';
        % elseif strncmpi(kernel,'lin',3);  kernel = 'linear';
        % elseif strncmpi(kernel,'',4); kernel = 'custom';
        % else error('! fatal error: unknown kernel function specified.');
        % end

        out = struct();

        traindata = c.shuffle([data(1).train.real; ...
                            data(1).train.pseudo] );
        trainlabels = traindata(:,67);

        fprintf('#\n+ test\n+ log2C\t%4.2f\n+ log2gamma\t%4.2f\n',...
                log2(C), log2(gamma))

        try
            if isempty(strfind(kernel,'uni'))
                % train RBF or linear with current part, Nth param
                model = mysvm_train( lib, kernel, ...
                                     traindata(:,features), trainlabels, ...
                                     C, gamma, false, 1e-6 );
            else
                % train custom kernel
                model = mysvm_train( lib, kernel, ...
                                     traindata(:,features), trainlabels, ...
                                     1e5, [C gamma], false, 1e-6);

            end

            for i=1:Ntest
                [cls_results] = mysvm_classify(model, data(1).test(i).data(:,features));

                t_res(i) = t_res(i)+mean(cls_results == data(1).test(i).class);
            end
        catch e
            fprintf('! fatal: %s / %s', e.identifier, e.message)
        end % try

        for i=1:Ntest
            out(i).name = data(1).test(i).name;
            out(i).class = data(1).test(i).class;
            out(i).size = size(data(1).test(i).data,1);
            out(i).rate = t_res(i);
        end
    end

    % init time counter
    c.time_init = @time_init;
    function out = time_init()
        out.begintime = clock;
        out.time = 0;
        out.count = 0;
    end

    % tick timer
    c.time_tick = @time_tick;
    function out = time_tick(in,count)
        out.begintime = in.begintime;
        out.count = in.count + count;
        out.time  = round(etime(clock,in.begintime));
        fprintf( '> time\t\t%02d:%02d\n', floor(out.time/60), mod(out.time,60))
    end

    % estimate remaining time to achieving #count operations
    c.time_estimate = @time_estimate;
    function time_estimate(in,count)
        if in.count < 1; return; end
        esttime = round(in.time/in.count * (count-in.count));
        estendt = datevec(datenum(0,0,0,0,0,esttime)+now);
        fprintf('# estimated\t%dm %d\tendtime\t%02d:%02d\n', ...
                floor(esttime/60), mod(esttime,60), fix(estendt(4:5)))
    end

    % generate timestamp string
    c.time_string = @time_string;
    function out = time_string(time)
        out = datestr(time.begintime,'yyyy-mm-dd_HH.MM.SS');
    end
end
