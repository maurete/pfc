function y = pick(x,n)
    y = x(randsample(size(x,1),min(size(x,1),n)),:);
end