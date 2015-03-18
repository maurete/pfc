function net = mlp_xtrain(input, target, ival, tval, hidden, method, transfer_fcn, fann)
%MLP_TRAIN Train multi layer perceptron
% NET = MLP_TRAIN(INPUT,TARGET,HIDDEN,METHOD,TRANSFER_FUN)
% Trains an MLP and returns de trained network model.
%
% PARAMETER      DESCRIPTION
%
% input          Matrix with rows corresponding to training samples.
%
% target         Column vector with respective class (-1 or 1) for
%                each training sample.
%
% hidden         Row vector with size parameter for every hidden
%                layer. Defaults to 1 hidden layer with 10 neurons.
%
% method         Back-propagation method. Defaults to 'trainscg'.
%
% transfer_fcn   Transfer function for all layers. Default 'tansig'.
%
    if nargin < 8, fann = false; end
    if nargin < 7, transfer_fcn = []; end
    if nargin < 6 || isempty(method), method = 'trainrp'; end
    if nargin < 5, hidden = 10; end
    if ~isempty(hidden) && hidden(1) < 1, hidden = []; end
    if nargin < 4, tval = []; end
    if nargin < 3, ival = []; end

    MAX_IT = 1e12;

    % Works best when using [target, -target], but according to Matlab
    % documentation this should be binary as in [target>0,target<0].
    % target = [target,-target];
    target = [target,-target];
    tval   = [tval,-tval];

    if fann
        % FANN selected

        FANN_DIR = './mfann/';
        if isempty(which('trainFann')), addpath(FANN_DIR); end
        assert(~isempty(which('trainFann')), ...
               'mlp_xtrain: failed to load FANN fannTrain.')

        net = createFann([size(input,2), hidden, size(target,2)],1);

        if isempty(ival)
            % no validation data, beware of overtraining!
            net = trainFann(net,input,target,0,MAX_IT);
        else
            % train epoch-by-epoch watching for cv performance
            weights = [];
            err_tr = [];
            err_cv = [];
            cv_min = nan;
            for it = 1:MAX_IT
                net = trainFann(net,input,target,0,1);
                weights(:,it) = net.weights;
                err_tr(it) = mean(abs([testFann(net,input)-target]));
                err_cv(it) = mean(abs([testFann(net,ival)-tval]));

                if err_cv(it) < min(err_cv(1:it-1))
                    cv_min = it;
                elseif it-cv_min >= 5
                    net.weights = weights(:,cv_min);
                    break
                end
            end
        end

    else
        % Matlab Neural toolbox selected

        % Setup pattern recognition network.
        net = patternnet(hidden, method);
        net.trainParam.showWindow = 0;
        net.trainParam.time = 10;
        net.trainParam.epochs = MAX_IT;

        % Configure data partitionign
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
        if ~isempty(transfer_fcn), for i=1:length(net.layers)
                net.layers{i}.transferFcn = transfer_fcn;
        end, end

        % Configure, initialize and train network.
        net = configure(net, [input;ival]', [target;tval]');
        net = init(net);
        net = train(net, [input;ival]', [target;tval]');
    end
end
