function y = logunique ( x, precision )

%% logunique
% filters out vector elements with very similar log value
% according to precision parameter

    if nargin < 2
        precision = 1e-10;
    end

    horizontal = 0;
    if size(x,1)<size(x,2)
        horizontal=1;
        x=x';
    end
    N = size(x,1);

    s = sortrows(x);
    l = log(s);
    y = [ s(1,:) ];
    for i=2:N
        if sum(abs(l(i,:)-l(i-1,:)) > precision) > 0
            y = [ y; s(i,:) ];
        end
    end

    if horizontal
        y =y';
    end
end