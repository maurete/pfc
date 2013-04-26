
function xue1_mlp
    
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

    classes = [ ones(163,1); zeros(168,1) ];
    
    
    disp('Net: 32i 20 1o\n');
    net = patternnet([ 20 ]);     
    net = train(net, [real_train1; pseudo_train1]', classes');
    perf_real = sum(round(net(real_test1')))/30
    perf_pseudo = 1-sum(round(net(pseudo_test1')))/1000
    
    disp('Net: 32i 10 10 1o\n');
    net = patternnet([ 10 10 ]);     
    net = train(net, [real_train1; pseudo_train1]', classes');
    perf_real = sum(round(net(real_test1')))/30
    perf_pseudo = 1-sum(round(net(pseudo_test1')))/1000
    
    disp('Net: 32i 20 10 1o\n');
    net = patternnet([ 20 10 ]);     
    net = train(net, [real_train1; pseudo_train1]', classes');
    perf_real = sum(round(net(real_test1')))/30
    perf_pseudo = 1-sum(round(net(pseudo_test1')))/1000
    
    disp('Net: 32i 20 10 10 1o\n');
    net = patternnet([ 20 10 10 ]);     
    net = train(net, [real_train1; pseudo_train1]', classes');
    perf_real = sum(round(net(real_test1')))/30
    perf_pseudo = 1-sum(round(net(pseudo_test1')))/1000

    disp('Net: 32i 32 20 10 1o\n');
    net = patternnet([ 32 20 10 ]);     
    net = train(net, [real_train1; pseudo_train1]', classes');
    perf_real = sum(round(net(real_test1')))/30
    perf_pseudo = 1-sum(round(net(pseudo_test1')))/1000

    disp('Net: 32i 60 10 1o\n');
    net = patternnet([ 60 10 ]);     
    net = train(net, [real_train1; pseudo_train1]', classes');
    perf_real = sum(round(net(real_test1')))/30
    perf_pseudo = 1-sum(round(net(pseudo_test1')))/1000
    disp('Net: 32i 60 32 20 10 10 1o\n');
    net = patternnet([ 60 32 20 10 10 ]);     
    net = train(net, [real_train1; pseudo_train1]', classes');
    perf_real = sum(round(net(real_test1')))/30
    perf_pseudo = 1-sum(round(net(pseudo_test1')))/1000
    
    
    %svm_model = svmtrain( [real_train1; pseudo_train1], classes, 'Kernel_Function', 'rbf');

    % TEST hsa
    %svmclassify(svm_model, real_test1)'
    %error_hsa = 1-sum(svmclassify(svm_model, real_test1))/30
    % TEST pseudo
    %svmclassify(svm_model, pseudo_test1)'
    %error_pseudo = sum(svmclassify(svm_model, pseudo_test1))/1000
    
end
