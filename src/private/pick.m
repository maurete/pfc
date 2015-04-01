function y = pick(x,n)
    y = x(randperm(size(x,1),min(size(x,1),n)),:);
end
