function net = mlp_xtrain(input, target, ival, tval, hidden, method, ...
                          transfer_fun, fann)
%MLP_XTRAIN Train multi layer perceptron
%
%  NET = MLP_XTRAIN(INPUT,TARGET,HIDDEN,METHOD,TRANSFER_FUN) Trains an MLP
%  network and returns de trained network model. The optimal network is
%  considered to be the one with lowest error over the validation samples.
%  Validation samples can be either supplied in the input arguments IVAL/TVAL
%  or else they are automatically taken as 20% of the training dataset.
%  INPUT is the data matrix with rows corresponding to training samples,
%  TARGET is a column vector with respective class (-1 or 1) for each sample,
%  IVAL is an input matrix with rows corresponding to validation samples,
%  TVAL is a column vector with target classes for each validation sample,
%  HIDDEN is a row vector with size parameter for each hidden layer,
%  METHOD specifies the back-propagation method (defaults to 'trainrp'),
%  TRANSFER_FUN sets the transfer function for all layers (default 'tansig'),
%  FANN is a binary flag specifying wether to use libFANN instead of
%  Matlab's own Neural Network Toolbox.
%

    if nargin < 8, fann = false; end
    if nargin < 7, transfer_fun = []; end
    if nargin < 6 || isempty(method), method = 'trainrp'; end
    if nargin < 5, hidden = 10; end
    if ~isempty(hidden) && hidden(1) < 1, hidden = []; end
    if nargin < 4, tval = []; end
    if nargin < 3, ival = []; end

    config; % Load global settings

    MAX_IT = 1e12;

    % Works best when using [target, -target], but according to Matlab
    % documentation this should be binary as in [target>0,target<0].
    % target = [target,-target];
    target = [target,-target];
    tval   = [tval,-tval];

    if fann
        % FANN selected
        if isempty(which('trainFann')), addpath(FANN_DIR); end
        assert(~isempty(which('trainFann')), ...
               'mlp_xtrain: failed to load FANN fannTrain.')

        net = createFann([size(input,2), hidden, size(target,2)],1);

        if isempty(ival)
            % No validation data provided, create it
            [tri tsi] = stpart(randi(1e5),size(input,1),1,0.2,0);
            ival = input(tsi,:);
            tval = target(tsi,:);
            input = input(tri,:);
            target = target(tri,:);
        end

        % Train epoch-by-epoch watching for cv performance
        weights = [];
        err_tr = [];
        err_cv = [];
        cv_min = nan;
        for it = 1:MAX_IT
            net = trainFann(net,input,target,0,1);
            weights(:,it) = net.weights;
            err_tr(it) = mean(abs([ testFann(net,input)*[1;-1]-target*[1;-1] ]));
            err_cv(it) = mean(abs([ testFann(net,ival)*[1;-1]-tval*[1;-1] ]));

            if err_cv(it) < min(err_cv(1:it-1))
                cv_min = it;
            elseif it-cv_min >= 5
                net.weights = weights(:,cv_min);
                break
            end
        end

    else
        % Matlab Neural toolbox selected

        % Setup pattern recognition network.
        net = patternnet(hidden, method);
        net.trainParam.showWindow = 0;
        %net.trainParam.time = 10;
        %net.trainParam.epochs = MAX_IT;

        % Configure data partitioning
        if ~isempty(ival)
            net.divideFcn = 'divideind';
            net.divideParam.trainInd = [1:size(input,1)];
            net.divideParam.valInd   = [size(input,1)+[1:size(ival,1)]];
            net.divideParam.testInd  = [];
        else
            net.divideFcn = 'dividerand';
            net.divideParam.trainRatio = 0.8;
            net.divideParam.valRatio   = 0.2;
            net.divideParam.testRatio  = 0;
        end

        % Set transfer function if requested.
        if ~isempty(transfer_fun), for i=1:length(net.layers)
                net.layers{i}.transferFcn = transfer_fun;
        end, end

        % Configure, initialize and train network.
        net = configure(net, [input;ival]', [target;tval]');
        net = init(net);
        net = train(net, [input;ival]', [target;tval]');
    end

end
