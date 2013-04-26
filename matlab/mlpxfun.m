function res = mlpxfun( trndata, trnlbls, tstdata, hidden_layers )

    trndata = trndata';
    trnlbls = double(trnlbls)'-1;
    tstdata = tstdata';
    
    net = patternnet(hidden_layers);
    net = train(net, trndata, trnlbls);
    res = net(tstdata);
    res = nominal([[ res > 0.5 ]*1]');
