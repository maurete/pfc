function y = logunique ( x, precision )
    
%% logunique
% filters out vector elements with very similar log value
% according to precision parameter
    
    if nargin < 2
        precision = 1e-10;
    end
    
    s = sort(x);
    l = log(s);
    y = [ s(1) ];
    for i=2:length(l)
        if abs(l(i)-l(i-1)) > precision
            if isrow(x)
                y = [ y s(i) ];
            else
                y = [ y; s(i) ];
            end
        end
    end
end