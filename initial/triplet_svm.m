function [sensit specif sigmas boxcns] = triplet_svm ( tries, sigma, ...
                                                      boxconstraint )
    
    addpath('./util/');
    
    if nargin < 1
        tries = 10;
    end

    % Leo los datos originales
    ftrain_real   = fastaread('train_hsa_163.txt');
    ftrain_pseudo = fastaread('train_cds_168.txt');
    ftest_real    = fastaread('test_hsa_30.txt');
    ftest_pseudo  = fastaread('test_cds_1000.txt');
    ftest_updated = fastaread('test_hsa_updated.txt');
    
    train_real   = zeros(163,32);
    train_pseudo = zeros(168,32);
    test_real    = zeros(30,32);
    test_pseudo  = zeros(1000,32);
    test_updated = zeros(39,32);
    
    for i=1:163
        train_real(i,:) = triplet(ftrain_real(i).Sequence, ftrain_real(i).Fold);
    end
    for i=1:30
        test_real(i,:) = triplet(ftest_real(i).Sequence, ftest_real(i).Fold);
    end
    for i=1:168
        train_pseudo(i,:) = triplet(ftrain_pseudo(i).Sequence, ftrain_pseudo(i).Fold);
    end
    for i=1:1000
        test_pseudo(i,:) = triplet(ftest_pseudo(i).Sequence, ftest_pseudo(i).Fold);
    end
    for i=1:39
        test_updated(i,:) = triplet(ftest_updated(i).Sequence, ftest_updated(i).Fold);
    end
    
    [traindata fff ooo] = scale([train_real; train_pseudo]);
    trainlbls = [ones(163,1); zeros(168,1)];

    sigmas = [0.6 0.8 1 1.2 1.5 1.8 2 2.2 2.8 3 4 18 18.5 19 19.5 ...
              20 20.5 21 22];
    %boxcns = [0.01 0.1 0.5 1 2 5 10 100 1000 1e4 1e5 1e6];
    boxcns = [1 10 100 1e3 1e4 1e5 1e6 1e7 1e8 1e9 1e10];

    test_real = scale(test_real, fff, ooo);
    test_pseudo = scale(test_pseudo, fff, ooo);
    test_updated = scale(test_updated, fff, ooo);

    sensit  = zeros(length(sigmas),length(boxcns));
    specif  = zeros(length(sigmas),length(boxcns));
    sensit2 = zeros(length(sigmas),length(boxcns));

    matlabpool(2);
    for s=1:length(sigmas)
        for b=1:length(boxcns)
            try                
                se = zeros(1,tries);
                sp = zeros(1,tries);
                up = zeros(1,tries);
                
                parfor i = 1:tries
                    idx = randperm(331);
                    
                    model = svmtrain(traindata(idx,:),trainlbls(idx,:),'Kernel_Function','rbf', ...
                     'rbf_sigma',sigmas(s),'boxconstraint',boxcns(b));

                    se(i) = sum(double(svmclassify(model, ...
                                                   test_real)))/30;
                    sp(i) = 1-sum(double(svmclassify(model, ...
                                                     test_pseudo)))/1000;
                    up(i) = sum(double(svmclassify(model, ...
                                                   test_updated)))/39;
                                      
                end
                
                fprintf( 'sigma=%8.6g, boxcn=%8.6g, se=%-8.6f, sp=%-8.6f, up=%-8.6f\n', ...
                 sigmas(s), boxcns(b), mean(se), mean(sp), mean(up) )
                
            catch e
                se = 0;
                sp = 0;
                up = 0;
            end
            sensit(s,b) = mean(se);
            specif(s,b) = mean(sp);
            sensit2(s,b) = mean(up);
        end
    end
    matlabpool close;
end
