function y = stshuffle(s,x)
    y = x(strandsample(s,size(x,1),size(x,1)),:);
end
