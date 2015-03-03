function ztest_model_sigmoid( dataset, featset, C, gamma)
    if nargin < 4 || isempty(gamma),     gamma = 1;     end
    if nargin < 3 || isempty(C),             C = 1;     end
    if nargin < 2 || isempty(featset), featset = 1;     end
    if nargin < 1 || isempty(dataset), dataset = 'xue'; end

    com = common;
    features = com.featindex{featset};

    fprintf('loading %s data..\n', dataset)
    [data.train data.test] = load_data(dataset, 114609);
    trainset = com.stshuffle(213,[data.train.real; data.train.pseudo]);
    trainlabels = trainset(:,67);
    trainset = trainset(:,features);

    libsvmmodel = mysvm_train( 'libsvm', 'rbf', trainset, trainlabels, C, ...
                               gamma, false, 1e-6, true );
    matsvmmodel = mysvm_train( 'matlab', 'rbf', trainset, trainlabels, C, ...
                               gamma, false, 1e-6, true );

    cvoutl  = zeros(size(trainset,1),1);
    cvoutr  = zeros(size(trainset,1),1);
    cvmatl  = zeros(size(trainset,1),1);
    cvmatr  = zeros(size(trainset,1),1);

    [cvtrain cvtest] = stpart(4357984,size(trainset,1),5);
    for p=1:5
        cvmodel = mysvm_train( 'libsvm', 'rbf', trainset(cvtrain(:,p)), ...
                               trainlabels(cvtrain(:,p)), C, gamma, false, 1e-10);
        matmodel = mysvm_train( 'matlab', 'rbf', trainset(cvtrain(:,p)), ...
                                trainlabels(cvtrain(:,p)), C, gamma, false, 1e-10);

        [cvoutl(cvtest(:,p)), cvoutr(cvtest(:,p))] = ...
            mysvm_classify(cvmodel, trainset(cvtest(:,p)));

        [cvmatl(cvtest(:,p)), cvmatr(cvtest(:,p))] = ...
            mysvm_classify(matmodel, trainset(cvtest(:,p)));

    end

    if any(cvoutl==0)
    [cvoutl(find(cvoutl==0)) cvoutr(find(cvoutl==0))] = mysvm_classify(libsvmmodel, trainset(find(cvoutl==0),:));
    end
    if any(cvmatl==0)
    [cvmatl(find(cvmatl==0)) cvmatr(find(cvmatl==0))] = mysvm_classify(matsvmmodel, trainset(find(cvmatl==0),:));
    end

    sortidx = 1:length(cvoutl);%[find(trainlabels<0);find(trainlabels>0)];

    scalelib = (max(cvoutr)-min(cvoutr))/2;
    scalemat = (max(cvmatr)-min(cvmatr))/2;

    cvoutl = cvoutl(sortidx);
    cvmatl = cvmatl(sortidx);
    cvoutr = cvoutr(sortidx)./scalelib;
    cvmatr = cvmatr(sortidx)./scalemat;

    [aux1 aux2] = mysvm_classify(libsvmmodel, trainset);

    %[cvoutl(1:50) cvoutr(1:50) aux1(1:50) aux2(1:50)]

    a0 = libsvmmodel.ProbA
    b0 = libsvmmodel.ProbB

    sigtrain = @model_sigmoid_train;

    [libsvm_labAB] = sigtrain(cvoutl, trainlabels)
    [libsvm_dvAB] = sigtrain(cvoutr, trainlabels);%.*[2 sqrt(2)/2]
    %[l_abgi] = model_sigmoid_train(cvoutl/2, trainlabels)
    %[r_abgi] = model_sigmoid_train(cvoutr/2, trainlabels)

    [matlab_labAB] = sigtrain(cvmatl, trainlabels)
    [matlab_dvAB] = sigtrain(cvmatr, trainlabels);%.*[2 sqrt(2)/2]
    %[ml_abgi] = model_sigmoid_train(cvmatl/2, trainlabels)
    %[mr_abgi] = model_sigmoid_train(cvmatr/2, trainlabels)

    xdom = linspace(-2, 2);
    L = length(cvoutl);
    [dlibr] = cumsum(hist(cvoutr,xdom))/L;
    [dlibl] = cumsum(hist(cvoutl,xdom))/L;
    [dmatr] = cumsum(hist(cvmatr,xdom))/L;
    [dmatl] = cumsum(hist(cvmatl,xdom))/L;

    [ y0 ] = model_sigmoid(xdom,[a0 b0]);
    %[ yliblab ] = model_sigmoid(xdom,[libsvm_labAB]);
    [ ylibdv ] = model_sigmoid(xdom,[libsvm_dvAB]);
    %[ ymatlab ] = model_sigmoid(xdom,[matlab_labAB]);
    [ ymatdv ] = model_sigmoid(xdom,[matlab_dvAB]);
    %[ ysl ] = model_sigmoid(xdom,[a0 b0]);

    figure
    hold all
    h = [];
    l = {};

    h(end+1) = plot(xdom, dlibr);
    l{end+1} = 'libsvm real output';
    h(end+1) = plot(xdom, dlibl);
    l{end+1} = 'libsvm label output';
    h(end+1) = plot(xdom, dmatr);
    l{end+1} = 'matlab real output';
    h(end+1) = plot(xdom, dmatl);
    l{end+1} = 'matlab label output';

    h(end+1) = plot(xdom, y0);
    l{end+1} = 'libsvm-A-B sigmoid';
    % h(end+1) = plot(xdom, yliblab);
    % l{end+1} = 'libsvm label-fitted sigmoid';
    h(end+1) = plot(xdom, ylibdv);
    l{end+1} = 'libsvm real-fitted sigmoid';
    % h(end+1) = plot(xdom, ymatlab);
    % l{end+1} = 'matlab label-fitted sigmoid';
    h(end+1) = plot(xdom, ymatdv);
    l{end+1} = 'matlab real-fitted sigmoid';

    % h(end+1) = plot(xdom, cumsum(hist(aux2,xdom))/L);
    % l{end+1} = 'libsvm decision values, whole training set';

    legend(h,l)
    ylabel('svm output value')
    xlabel('prob(y=1|x)')
    hold off


end