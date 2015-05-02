function [v,ins,req] = insert(vec, values, tol)
% insert elements into vector preserving order
% and keeping only unique values

    % default tolerance
    if nargin < 3, tol = 1e-6; end

    % find sort order for <vec>
    s = 'ascend';
    if findorder(vec) < 0, s = 'descend';
    end

    % highlight <value> elements to be inserted
    values = values(:);
    do_ins = true(numel(values),1);
    for i=1:numel(values)
        if min(abs(vec-values(i)))<tol, do_ins(i) = false;
        end
    end

    % insert elements into output vector and sort them
    [v idx] = sort([vec(:);values(do_ins)],s);

    % flag newly inserted elements
    ins = false(size(v));
    ins(idx(numel(vec)+1:numel(v))) = true;

    % flags <values> positions in v
    req = false(size(v));
    for i=1:numel(values)
        req(find([abs(v-values(i))<tol])) = true;
    end

    if isrow(vec)
        v = v';
        ins = ins';
        req = req';
    end

end
