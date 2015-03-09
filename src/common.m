classdef common
    properties
        % featureset indexes
        featindex = { 1:66; 1:32; 33:36; 37:59; 60:66; 1:36; [1:36 60:66]; ...
                      37:66; 1:59; 33:66; [33:36 60:66]; 33:59; [1:32 60:66]; ...
                      [1:32 37:59]; [1:32 37:66] };

        % featureset names
        featname = {'all-features', 'triplet', 'triplet-extra', 'sequence', ...
                    'structure', 'triplet+extra', 'not-sequence', 'seq+struct', ...
                    'not-structure', 'not-triplet', 'extra+str', 'extra+sequence', ...
                    'triplet+structure', 'triplet+sequence', 'not-extra' };
    end
    methods

        function s = strandsample(o,seed, population, nsamples)
            a = rng(seed);
            s = randsample(population, nsamples);
            rng(a);
        end

        % pick and shuffle mini-functions
        function y = pick(o,x,n)
            y = x(randsample(size(x,1),min(size(x,1),n)),:);
        end
        function y = shuffle(o,x)
            y = x(randsample(size(x,1),size(x,1)),:);
        end
        function y = stpick(o,s,x,n)
            y = x(o.strandsample(s,size(x,1),min(size(x,1),n)),:);
        end
        function y = stshuffle(o,s,x)
            y = x(o.strandsample(s,size(x,1),size(x,1)),:);
        end

        % write output file headers
        function write_init(o,filename, extended, varargin)
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
        function write_train_info(o,file,setup,fset,kern,param1,param2,result,seed,varargin)
            fid = fopen( file, 'a' );
            if nargin<9, fprintf(fid, '%s\t%d\t%s\t%d\t%s\t%9.8g\t%9.8g\t%9.8g\n', ...
                                 setup, 0, 'train', fset, kern, param1, param2, result );
            else, fprintf(fid, '%s\t%d\t%s\t%d\t%s\t%9.8g\t%9.8g\t%9.8g\t%d\n', ...
                          setup, 0, 'train', fset, kern, param1, param2, result, seed );
            end
            fclose(fid);
        end

        % write test information to output file
        function write_test_info(o,file,setup,fset,kern,param1,param2,test_info, seed, varargin)
            fid = fopen( file, 'a' );
            for i=1:length(test_info)
                if nargin<9
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
        function print_train_info(c, problem)
            npart = problem.npartitions;
            nreal = sum(problem.trainlabels>0);
            npseu = sum(problem.trainlabels<0);

            [tidx,~] = find(problem.partitions.train);
            [vidx,~] = find(problem.partitions.validation);
            train_real = round(sum(problem.trainlabels(tidx)>0)/npart);
            train_pseu = round(sum(problem.trainlabels(tidx)<0)/npart);
            valid_real = round(sum(problem.trainlabels(vidx)>0)/npart);
            valid_pseu = round(sum(problem.trainlabels(vidx)<0)/npart);

            fprintf('> dataset\t%s\n', problem.dataset );
            fprintf('> featureset\t%d\t%s\n', problem.featureset, ...
                    c.featname{problem.featureset});
            fprintf(['> partitions\t%d\n#\n', ...
                     '# dataset\tsize\t#train\t#test\n', ...
                     '# -------\t----\t------\t-----\n', ...
                     '> real\t\t%d\t%d\t%d\n', ...
                     '> pseudo\t%d\t%d\t%d\n#\n' ], ...
                    npart, nreal, train_real, valid_real, ...
                    npseu, train_pseu, valid_pseu);
        end

        % print testing information to screen
        function print_test_info(o,test_info)
            fprintf('# \t\tdataset\t\tclass\tsize\tperformance\n');
            fprintf('# \t\t-------\t\t-----\t----\t-----------\n');
            for i=1:length(test_info)
                fprintf('+ %24s\t%d\t%d\t%8.6f\n',...
                        test_info(i).name, test_info(i).class, ...
                        test_info(i).size, test_info(i).rate);
            end
            if isfield(test_info(1),'sen_source')
                fprintf('# \n')
                fprintf('# \tSE for dataset used in training\t\t%f\n',test_info(1).sen_source);
                fprintf('# \tSP for dataset used in training\t\t%f\n',test_info(1).spe_source);
                fprintf('# \tSE for other datasets\t\t\t%f\n',test_info(1).sen_other);
                fprintf('# \tSP for other datasets\t\t\t%f\n',test_info(1).spe_other);
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
        function init_matlabpool(o)
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
            % fprintf('# using %d matlabpool workers\n', matlabpool('size'));
        end

        % perform tests
        function out = run_tests(c, data, fset, randseed, kernel, lib, C, gamma)

            Ntest = length(data(1).test);
            t_res = zeros(Ntest,1);
            features = c.featindex{fset};
            Nrep = 5;

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

        % perform tests
        function out = test_csvm(o, problem, kernel, lib, C, kparam, svm_tol)
            if nargin < 7 || isempty(svm_tol), svm_tol = 1e-6; end

            ntests = length(problem(1).test);

            sen_source = [];
            spe_source = [];
            sen_other  = [];
            spe_other  = [];

            res_test = zeros(ntests,1);
            features = problem.featindex;

            try
                % train RBF or linear with current part, Nth param
                model = mysvm_train( lib, kernel, ...
                                     problem.trainset, problem.trainlabels, ...
                                     C, kparam, false, svm_tol );

                for i=1:ntests
                    [cls_results] = mysvm_classify(model, problem(1).test(i).data(:,features));
                    res_test(i)   = mean(cls_results == problem(1).test(i).class);
                    if problem(1).test(i).class == 1
                        if problem(1).test(i).trained, sen_source(end+1) = res_test(i);
                        else sen_other(end+1) = res_test(i); end
                    elseif problem(1).test(i).class == -1
                        if problem(1).test(i).trained, spe_source(end+1) = res_test(i);
                        else spe_other(end+1) = res_test(i); end
                    end
                end
            catch e
                fprintf('! fatal: %s / %s', e.identifier, e.message)
            end % try

            out = struct();
            out.sen_source = mean(sen_source);
            out.spe_source = mean(spe_source);
            out.sen_other = mean(sen_other);
            out.spe_other = mean(spe_other);
            for i=1:ntests
                out(i).name = problem(1).test(i).name;
                out(i).class = problem(1).test(i).class;
                out(i).size = size(problem(1).test(i).data,1);
            out(i).rate = res_test(i);
            end
        end

        % init time counter
        function out = time_init(o)
            out.begintime = clock;
            out.time = 0;
            out.count = 0;
        end

        % tick timer
        function out = time_tick(o,in,count)
            out.begintime = in.begintime;
            out.count = in.count + count;
            out.time  = round(etime(clock,in.begintime));
            fprintf( '> time\t\t%02d:%02d\n', floor(out.time/60), mod(out.time,60))
        end

        % estimate remaining time to achieving #count operations
        function time_estimate(o,in,count)
            if in.count < 1; return; end
            esttime = round(in.time/in.count * (count-in.count));
            estendt = datevec(datenum(0,0,0,0,0,esttime)+now);
            fprintf('# estimated\t%dm %d\tendtime\t%02d:%02d\n', ...
                    floor(esttime/60), mod(esttime,60), fix(estendt(4:5)))
        end

        % generate timestamp string
        function out = time_string(o,time)
            out = datestr(time.begintime,'yyyy-mm-dd_HH.MM.SS');
        end

        % void function: simply does nothing
        function void(varargin)
        end

        % get normalized kernel name or test for specific type in str
        function out = get_kernel(o,kernel, str, exact, varargin)
            if nargin < 4 || isempty(exact), exact = true; end
            kstr = lower(kernel);
            % find kernel type and variant
            if strfind(kstr,'lin')
                out = 'linear';
                if strfind(kstr,'uni'), out = 'linear_uni'; end
                if strfind(kstr,'unc'), out = 'linear_unc'; end
            elseif strfind(kstr,'rbf')
                out = 'rbf';
                if strfind(kstr,'uni'), out = 'rbf_uni'; end
                if strfind(kstr,'unc'), out = 'rbf_unc'; end
            elseif strfind(kstr,'mlp')
                out = 'mlp';
            elseif strfind(kstr,'ign')
                out = '';
            else
                error('Unknown kernel selected: %s', kernel)
            end
            if nargin > 2 && ~isempty(str)
                if exact, out = strcmp(out, str);
                else out = any(strfind(str,out));
                end
            end
        end

    end
end
