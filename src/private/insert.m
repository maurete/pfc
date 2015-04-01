function [v ins req] = insert(vec, values)
% insert elements into vector preserving order
% and keeping only unique values

    TOL = 1e-6;

    s = 'ascend';
    if findorder(vec) < 0, s = 'descend';
    end

    if isrow(vec),
        values = reshape(values,1,[]);
        v = sort(unique([vec values]),s);
        %v = sort(builtin('_mergesimpts',[vec values],TOL),s);
    else
        values = reshape(values,[],1);
        v = sort(unique([vec;values]),s);
        %v = sort(builtin('_mergesimpts',[vec;values],TOL),s);
    end

    % ins flags new elements inserted into v
    ins = true(size(v));
    for i=1:length(vec)
        ins(find(v==vec(i))) = false;
        %ins(find([abs(v-vec(i))<TOL])) = false;
    end

    % req flags <values> positions in v
    req = false(size(v));
    for i=1:length(values)
        req(find(v==values(i))) = true;
        %req(find([abs(v-values(i))<TOL])) = true;
    end

    % if isrow(v), [v;ins;req],
    % else [v,ins,req]
    % end
end
