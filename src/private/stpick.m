function y = stpick(s,x,n)
    y = x(strandsample(s,size(x,1),min(size(x,1),n)),:);
end
