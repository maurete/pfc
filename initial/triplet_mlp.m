function [sen spc la] = triplet_mlp ( tries )
    
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

    test_real = scale(test_real, fff, ooo);
    test_pseudo = scale(test_pseudo, fff, ooo);
    test_updated = scale(test_updated, fff, ooo);

    la = {};
    la{1} =   [];
    la{2} =   8;
    la{3} =   16;
    la{4} =   20;
    la{5} =   24;
    la{6} =   32;
    la{7} =   40;
    la{8} =  [8  8];
    la{9} =  [16 8];
    la{10} =  [32 8];
    la{11} =  [64 8];
    la{12} =  [16 16];
    la{13} = [32 16];
    la{14} = [64 16];
    la{15} = [32 32];
    la{16} = [64 32];
    la{17} = [8  8  8];
    la{18} = [16  16  8];
    la{19} = [32  16  8];
    la{20} = [64  32  8];
    la{21} = [16  16  16];
    la{22} = [32  32  16];
    la{23} = [64  64  32];

    sen  = zeros(1,length(la));
    spc  = zeros(1,length(la));
    upd  = zeros(1,length(la));

    matlabpool(2);
    for l = 1:length(la)

        se = zeros(1,tries);
        sp = zeros(1,tries);
        up = zeros(1,tries);

        parfor i = 1:tries
            idx = randperm(331);

            net = patternnet( la{l} );
            %net.trainFcn = 'traingdm';
            net.trainParam.showWindow = 0;
            net.trainParam.epochs = 10000;

            net = train(net, traindata(idx,:)', trainlbls(idx,:)');

            se(i) = sum( [net(test_real')>0.5] )/30;
            sp(i) = 1-sum( [net(test_pseudo')>0.5] )/1000;
            up(i) = sum( [net(test_updated')>0.5] )/39;
        end

        fprintf( 'layout=[%-12s], se=%-8.6f, sp=%-8.6f, up=%-8.6f\n', ...
                 num2str([la{l}],'% g'), mean(se), mean(sp), mean(up) )

        sen(l) = mean(se);
        spc(l) = mean(sp);
        upd(l) = mean(up);
    end
    matlabpool close;

end