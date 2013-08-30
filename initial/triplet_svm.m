function [xvalerr sigmas boxcns sensit specif] = triplet_svm ( kernelfunc, boxconstraint, k )
    
    addpath('./util/');
    
    if nargin < 3
        k = 5;
        if nargin < 2
            boxconstraint = Inf;
            if nargin < 1
                kernelfunc = 'rbf';
            end
        end
    end

    % Leo los datos originales
    ftrain_real   = fastaread('train_hsa_163.txt');
    ftrain_pseudo = fastaread('train_cds_168.txt');
    ftest_real    = fastaread('test_hsa_30.txt');
    ftest_pseudo  = fastaread('test_cds_1000.txt');
    
    train_real   = zeros(163,32);
    train_pseudo = zeros(168,32);
    test_real    = zeros(30,32);
    test_pseudo  = zeros(1000,32);
    
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
    
    N = 163+168;
    part = cvpartition(N, 'kfold', k);
    [traindata fff ooo] = scale([train_real; train_pseudo]);
    trainlbls = [ones(163,1); zeros(168,1)];
    sigmas = [1 2 5 8 10 20 50 100 1000 1e4];
    boxcns = [0.01 0.1 0.5 1 2 5 10 100 1000 1e4 1e5];
    %results = zeros(length(sigmas),length(boxcns));
    test_real = scale(test_real, fff, ooo);
    test_pseudo = scale(test_pseudo, fff, ooo);

    xvalerr = zeros(length(sigmas),length(boxcns));
    sensit  = zeros(length(sigmas),length(boxcns));
    specif  = zeros(length(sigmas),length(boxcns));

    for s=1:length(sigmas)
        for b=1:length(boxcns)
            try
                err = crossval('mcr',traindata,trainlbls,'Predfun',...
                               @(trndata, trnlbls, tstdata)svmxfun(trndata, trnlbls,tstdata,sigmas(s),boxcns(b)),...
                           'partition',part);
                                
                model = load('__svm__struct__.mat');
                tr = double(svmclassify(model,test_real))-1;
                tp = double(svmclassify(model,test_pseudo))-1;
                se=sum(tr)/30;
                sp=1-sum(tp)/1000;
                fmt='% -9.6f';
                disp(['sig=',num2str(sigmas(s),fmt),' box=', ...
                      num2str(boxcns(b),fmt), ' err=', num2str(err,fmt), ...
                      ' se=', num2str(se,fmt), ' sp=', num2str(sp,fmt) ])
            catch e
                err=1;
                se = 0;
                sp = 0;
                %disp(e)
            end
            xvalerr(s,b) = err;
            sensit(s,b) = se;
            specif(s,b) = sp;
        end
    end
    %rtab = [ [ 5; sigmas'] [boxcns; xvalerr] ];
end
