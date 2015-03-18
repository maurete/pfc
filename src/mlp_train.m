function net = mlp_train(input, target, hidden, method, transfer_fcn)
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
    if nargin < 5, transfer_fcn = []; end
    if nargin < 4 || isempty(method), method = 'trainrp'; end
    if nargin < 3, hidden = 10; end
    if ~isempty(hidden) && hidden < 1, hidden = []; end

    % Works best when using [target, -target], but according to Matlab
    % documentation this should be binary as in [target>0,target<0].
    % target = [target,-target];
    target = [target,-target];

    % Setup pattern recognition network.
    net = patternnet(hidden, method);
    net.trainParam.showWindow = 0;
    net.trainParam.time = 10;
    net.trainParam.epochs = 1e12;

    % Set transfer function if requested.
    if ~isempty(transfer_fcn), for i=1:length(net.layers)
            net.layers{i}.transferFcn = transfer_fcn;
    end, end

    % Configure, initialize and train network.
    net = configure(net, input', target');
    net = init(net);
    net = train(net, input', target');
end

