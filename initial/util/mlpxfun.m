function [res net] = mlpxfun( trndata, trnlbls, tstdata, hidden_layers )

    trndata = trndata';
    trnlbls = double(trnlbls)'-1;
    tstdata = tstdata';
    
    net = patternnet(hidden_layers);
    %net.trainFcn = 'traingdm';
    %net.trainParam.showWindow = 0;
    net.trainParam.epochs = 10000;
    net = train(net, trndata, trnlbls);
    res = net(tstdata);
    res = nominal([[ res > 0.5 ]*1]');

    save('__mlp__struct__.mat','net');
