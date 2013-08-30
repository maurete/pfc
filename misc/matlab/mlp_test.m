function mlp_test
    data = csvread('../data/mypattern.data');
    
    
    net = patternnet([ 10 2 ]);
    net = train(net,data(:,1:2)',data(:,3)');
    
    test = zeros(230,2);
    
    r = 1;
    for i=-1:0.1:1
        for j=-1:0.1:1
            test(r,:)=[i j];
            r = r+1;
        end
    end
    
    result = net(test');
    
    scatter(test(:,1),test(:,2),5,result)