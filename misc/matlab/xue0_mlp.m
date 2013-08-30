function rtab = xue0_mlp ( kernelfunc, boxconstraint, k )
    
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
    real0 = fastaread('../rep1-xue/original/2_predict_secondary_structure_of_miRNAs/hsa.secondstructure');
    pseudo0 = fastaread('../rep1-xue/original/4_pseudo_miRNAs/8494_hairpins_over_fe_15_bp_18_from_cds.txt');
    % Elimino los no-hairpin
    real1 = strip_multiloop(real0);
    pseudo1 = strip_multiloop(pseudo0);
    % Calculo los vectores de triplets
    [real_train real_test] = partition(real1,163,30);
    [pseudo_train pseudo_test] = partition(pseudo1,168,1000);
    
    real_train1 = zeros(163,32);
    real_test1 = zeros(30,32);
    pseudo_train1 = zeros(168,32);
    pseudo_test1 = zeros(1000,32);
    
    for i=1:163
        real_train1(i,:) = triplet(real_train(i).Sequence, real_train(i).Fold);
    end
    for i=1:30
        real_test1(i,:) = triplet(real_test(i).Sequence, real_test(i).Fold);
    end
    for i=1:168
        pseudo_train1(i,:) = triplet(pseudo_train(i).Sequence, pseudo_train(i).Fold);
    end
    for i=1:1000
        pseudo_test1(i,:) = triplet(pseudo_test(i).Sequence, pseudo_test(i).Fold);
    end
    
    N = 163+168;
    part = cvpartition(N, 'kfold', k);
    traindata = [real_train1; pseudo_train1];
    trainlbls = [ones(163,1); zeros(168,1)];
    nhid = [1 2 3 4];
    nnod = [8 16 24 32];
    results = zeros(length(nhid),length(nnod));
    
    for nh = 1:length(nhid)
        for nn = 1:length(nnod)
            err = crossval('mcr',traindata,trainlbls,'Predfun',...
                @(trndata,trnlbls, tstdata)mlpxfun(trndata,trnlbls,tstdata,ones(1,nhid(nh))*nnod(nn)),...
                'partition',part);
            
            disp(['hnidden=',num2str(nhid(nh)),' nnodes=', num2str(nnod(nn)), ' err=', num2str(err)])
            
            results(nh,nn) = err;
        end
    end
    rtab = [ [0; nhid'] [nnod; results] ];
end
