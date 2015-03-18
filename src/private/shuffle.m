function y = shuffle(x)
    y = x(randsample(size(x,1),size(x,1)),:);
end
