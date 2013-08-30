function [xvalerr nhiddn nnodes se sp] = triplet_mlp ( )
    
    addpath('./util/');

    k = 5;

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
    nhiddn = [1 2 3 4];
    nnodes = [8 16 24 32];
    test_real = scale(test_real, fff, ooo);
    test_pseudo = scale(test_pseudo, fff, ooo);

    xvalerr = zeros(length(nhiddn),length(nnodes));
    se  = zeros(length(nhiddn),length(nnodes));
    sp  = zeros(length(nhiddn),length(nnodes));

    for nh = 1:length(nhiddn)
        for nn = 1:length(nnodes)
            
            err = crossval('mcr',traindata,trainlbls,'Predfun',...
                @(trndata,trnlbls, tstdata)mlpxfun(trndata,trnlbls,tstdata,ones(1,nhiddn(nh))*nnodes(nn)),...
                'partition',part);
                                
            load('__mlp__struct__.mat','net')
            tr = net(test_real')';
            tp = net(test_pseudo')';
            sens=sum(tr)/30;
            spec=1-sum(tp)/1000;
            fmt='% -9.6f';
            disp(['hidden=',num2str(nhiddn(nh),fmt),' nodes=', ...
                  num2str(nnodes(nn),fmt), ' err=', num2str(err,fmt), ...
                  ' se=', num2str(sens,fmt), ' sp=', num2str(spec,fmt) ])
        
            xvalerr(nh,nn) = err;
            se(nh,nn) = sens;
            sp(nh,nn) = spec;

        end
    end
    %rtab = [ [ 5; sigmas'] [boxcns; xvalerr] ];
end
