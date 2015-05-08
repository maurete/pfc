function mlp_gen_report(NEVAL)
    time = time_init();
    if nargin < 1, NEVAL = 10; end

    fprintf('> 1. Eval performance increase for 5 partitions vs 20 partitions\n')
    fprintf('> 1.0 Note: using 5 repeats\n')

    fprintf('> 1.1 Dataset xue, featset 2\n')
    % [hist5,nhid,res5] = single_test('xue',2,NEVAL,5,5);
    % [hist20,nhid,res20] = single_test('xue',2,NEVAL,20,5);
    % compare_tests(hist5,hist20,nhid,res5,res20);

    % fprintf('> 1.2 Dataset ng-multi, featset 5\n')
    % [hist5,nhid,res5] = single_test('ng-multi',5,NEVAL,5,5);
    % [hist20,nhid,res20] = single_test('ng-multi',5,NEVAL,20,5);
    % compare_tests(hist5,hist20,nhid,res5,res20);


    fprintf('> 2. Eval performance increase for 5 repeats vs 20 repeats\n')
    fprintf('> 2.0 Note: using 5 CV-partitions\n')

    % fprintf('> 2.1 Dataset xue, featset 2\n')
    % [hist5,nhid,res5] = single_test('xue',2,NEVAL,5,5);
    % [hist20,nhid,res20] = single_test('xue',2,NEVAL,5,20);
    % compare_tests(hist5,hist20,nhid,res5,res20);

    % fprintf('> 2.2 Dataset ng-multi, featset 5\n')
    % [hist5,nhid,res5] = single_test('xue',2,NEVAL,5,5);
    % [hist20,nhid,res20] = single_test('xue',2,NEVAL,5,20);
    % compare_tests(hist5,hist20,nhid,res5,res20);

    fprintf('> 3. Eval performance increase for symmetric vs non-symmetric\n')
    fprintf('> 3.0 Note: using 5 CV-partitions, 5 repeats\n')

    % fprintf('> 3.1 Dataset xue, featset 2\n')
    % [hist5,nhid,res5] = single_test('xue',2,NEVAL,5,5,false);
    % [hist20,nhid,res20] = single_test('xue',2,NEVAL,5,5,true);
    % compare_tests(hist5,hist20,nhid,res5,res20);

    % fprintf('> 3.2 Dataset ng-multi, featset 5\n')
    % [hist5,nhid,res5] = single_test('ng-multi',5,NEVAL,5,5,false);
    % [hist20,nhid,res20] = single_test('ng-multi',5,NEVAL,5,5,true);
    % compare_tests(hist5,hist20,nhid,res5,res20);

    fprintf('> 4. Eval performance increase for balanced vs non-balanced\n')
    fprintf('> 4.0 Note: using 5 CV-partitions, 5 repeats\n')

    % fprintf('> 4.1 Dataset xue, featset 2\n')
    % [hist5,nhid,res5] = single_test('xue',2,NEVAL,5,5,false,false);
    % [hist20,nhid,res20] = single_test('xue',2,NEVAL,5,5,false,true);
    % compare_tests(hist5,hist20,nhid,res5,res20);

    fprintf('> 4.2 Dataset ng-multi, featset 5\n')
    [hist20,nhid,res20] = single_test('ng-multi',5,NEVAL,5,5,false,true);
    [hist5,nhid,res5] = single_test('ng-multi',5,NEVAL,5,5,false,false);
    compare_tests(hist5,hist20,nhid,res5,res20);


    %%%%%%%%%%
    function [hist,nhid,res] = single_test(dataset, featset, neval, npart, repeat, sym, bal)
        if nargin < 7, bal = false; end
        if nargin < 6, sym = false; end
        problem = problem_load(dataset,featset,npart,max([1/npart,0.1]),[],sym, bal);
        % Initialize results variables
        hist = struct();
        hist.param = [];
        hist.dataset = dataset;
        hist.featset = featset;
        hist.npart = npart;
        hist.repeat = repeat;
        for j=1:length(problem.test)
            hist(j).name  = problem.test(j).name;
            hist(j).class = problem.test(j).class;
            hist(j).size  = size(problem.test(j).data,1);
            hist(j).rate  = [];
        end
        nhid = [];
        res = [];
        for i = 1:neval
            [hist(1).param(i),tmph,tmpres,tmpn,tmp] = select_model_mlp(problem,'gm',[],5,false);
            hist(1).sen_source(i) = tmp.sen_source;
            hist(1).spe_source(i) = tmp.spe_source;
            hist(1).sen_other(i) = tmp.sen_other;
            hist(1).spe_other(i) = tmp.spe_other;
            for j=1:length(problem.test)
                hist(j).rate(i)  = tmp(j).rate;
            end
            res = [res tmpres(:,find(strcmp('gm',tmpn)))];
            nhid = tmph;
            fprintf('#');
        end
        fprintf('\n');
    end

    function compare_tests(hist1,hist2,nhid,res1,res2)
        fprintf('# test 1: %s featureset %d, %d partitions, %d repeats\n', ...
                hist1(1).dataset, hist1(1).featset, hist1(1).npart, hist1(1).repeat)
        fprintf('# test 2: %s featureset %d, %d partitions, %d repeats\n', ...
                hist2(1).dataset, hist2(1).featset, hist2(1).npart, hist2(1).repeat)

        fprintf('\n# results:\n# \t\tdataset\t\tclass\tsize\ttest1 avg(mad)\t\ttest2 avg(mad)\n');
        fprintf('# \t\t-------\t\t-----\t----\t---------------\t-----------------\n');
        for i=1:length(hist5)
            fprintf('+ %24s\t%d\t%d\t%5.2f(%5.2f)\t%5.2f(%5.2f)\n',...
                    hist1(i).name, hist1(i).class, ...
                    hist1(i).size, 100*mean(hist1(i).rate), 100*mad(hist1(i).rate), ...
                    100*mean(hist2(i).rate), 100*mad(hist2(i).rate));
        end

        fprintf('# \tsame source as train, positive\t\t%5.2f(%5.2f)\t%5.2f(%5.2f)\n', ...
                100*mean(hist1(1).sen_source), 100*mad(hist1(1).sen_source), ...
                100*mean(hist2(1).sen_source), 100*mad(hist2(1).sen_source));
        fprintf('# \tsame source as train, negative\t\t%5.2f(%5.2f)\t%5.2f(%5.2f)\n', ...
                100*mean(hist1(1).spe_source), 100*mad(hist1(1).spe_source), ...
                100*mean(hist2(1).spe_source), 100*mad(hist2(1).spe_source));
        fprintf('# \t\tother source, positive\t\t%5.2f(%5.2f)\t%5.2f(%5.2f)\n', ...
                100*mean(hist1(1).sen_other), 100*mad(hist1(1).sen_other), ...
                100*mean(hist2(1).sen_other), 100*mad(hist2(1).sen_other));
        fprintf('# \t\tother source, negative\t\t%5.2f(%5.2f)\t%5.2f(%5.2f)\n', ...
                100*mean(hist1(1).spe_other), 100*mad(hist1(1).spe_other), ...
                100*mean(hist2(1).spe_other), 100*mad(hist2(1).spe_other));

        fprintf('\n#\tmode for best # neurons in hidden layer (1) = %d (%d/%d)\n', ...
                mode(hist1(1).param), numel(find([hist1(1).param==mode(hist1(1).param)])), length(hist1(1).param) );
        fprintf('#\tmode for best # neurons in hidden layer (2) = %d (%d/%d)\n', ...
                mode(hist2(1).param), numel(find([hist2(1).param==mode(hist2(1).param)])), length(hist2(1).param) );

        figure
        hold all
        h = [];
        l = {};
        h(1) = errorbar(nhid,mean(res1,2),mad(res1,0,2));
        l{1} = sprintf('%d part %d rep', hist1(1).npart, hist1(1).repeat);
        h(2) = errorbar(nhid,mean(res20,2),mad(res20,0,2));
        l{2} = sprintf('%d part %d rep', hist2(1).npart, hist2(1).repeat);
        legend(h,l)
        xlabel( 'hidden layer size' )
        ylabel( 'train Gm' )
        title(sprintf('dataset %s, featset %d', hist1(1).dataset, hist1(1).featset));
        grid on
        hold off

    end

end