function y = shuffle(x)
    % shuffle columns of x
    y = x(randperm(size(x,1),size(x,1)),:);
end
