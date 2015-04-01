function s = findorder(vec)

    s = 1;
    if max(vec(:)) == min(vec(:))
        s = 0;
    elseif numel(vec) > 1 && all( vec(2:end)-vec(1:end-1) <=0 )
        s = -1;
    end

end