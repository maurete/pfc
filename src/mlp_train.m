% mlp training function for cross-validation
function net = mlp_train(input, target, hidden, method)
    if nargin < 4 || isempty(method), method = 'trainrp'; end
    if nargin < 3, hidden = 10; end
    if ~isempty(hidden)
        % keep only one layer
        hidden = hidden(1);
        if hidden < 1, hidden = []; end
    end

    target = [target,-target];
    net = patternnet( [hidden] );
    net.trainFcn = method;
    net.trainParam.showWindow = 0;
    for i=1:length(net.layers), net.layers{i}.transferFcn = 'logsig'; end
    %net.trainParam.time = 10;
    %net.trainParam.epochs = 2000000000000;
    net = init(net);
    net = configure(net, input', target');
    net = train(net, input', target');
end

