function [x,f,xhist,fhist] = opt_rprop(fun, dfun, x0, tol, max_it, delta0, dmax)

    if nargin < 7 || isempty(dmax), dmax = 2; end
    if nargin < 6 || isempty(delta0), delta0 = 0.01; end

    if ~isa(dfun, 'function_handle'), dfun_in_fun = true;
    else dfun_in_fun = false;
    end

    np     = 1.2; %1.2
    nm     = 0.5; %0.5
    dmin   = 0;
    delta  = delta0 .* ones(size(x0));
    df0    = zeros(size(x0));
    f0 = 0;
    xk = x0;

    % param history to watch for convergence
    xhist = []; % x0;
    fhist = []; % fun(x0);

    for k = 1:max_it
        if dfun_in_fun, [fk dfk] = fun(xk);
        else fk = fun(xk); dfk = dfun(xk);
        end
        xhist(end+1,:) = xk;
        fhist(end+1) = fk;

        for i=1:length(xk)
            if dfk(i) * df0(i) > 0
                delta(i) = min(dmax, np*delta(i));
            elseif dfk(i) * df0(i) < 0
                delta(i) = max(dmin, nm*delta(i));
            end
            xk(i) = xk(i) - delta(i) * sign(dfk(i));
            df0(i) = dfk(i);
        end

        %f0 = fk;

        if max(abs(delta)) < tol
            fprintf('rprop stop: max(delta) < tol\n')
            break;
        end
        if max(abs(dfk)) < tol
            fprintf('rprop stop: max(dfk) < tol\n')
            break;
        end
        if length(xk) > 1
            fprintf('rprop %d xk [%f;%f] fk %f dfk [%d;%d] delta [%f;%f] \n', k, xk(1), xk(2), ...
                    fk, sign(dfk(1)), sign(dfk(2)), delta(1), delta(2))
        end

    end

    x = xk; f = fk;

end