% mlp testing function for cross-validation
function out = mlp_classify(net, input)
    out = net(input');
    out = out';
    out = out*[1;-1];
end