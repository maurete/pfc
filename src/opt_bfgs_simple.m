function [xk, fk, xhist, fhist] = opt_bfgs_simple ( fun, dfun, x0, tol, max_it, disp )

    if nargin < 6, disp = true; end
    if nargin < 5, max_it =  100; end
    if nargin < 4, tol    = 1e-6; end

    if ~isa(dfun, 'function_handle'), dfun_in_fun = true;
    else dfun_in_fun = false;
    end

    % gradient norm tol
    gtol = tol*length(x0);

    %% BFGS Quasi-Newton method

    if dfun_in_fun, [f0 df0] = fun(x0);
    else f0 = fun(x0); df0 = dfun(x0);
    end

    % param history to watch for convergence
    xhist = x0;
    fhist = f0;

    N = numel(x0);
    Hk = eye(N);
    xk = x0;
    fk = f0;
    dfk = df0;

    sk =  2*gtol;
    pk = -dfk*Hk';

    if disp && length(xk) > 1
        fprintf('min_bfgs %d xk [%f;%f] dfk [%f;%f] fk %f\n', 0, xk(1), xk(2), ...
                dfk(1), dfk(2), fk)
    else
        fprintf('min_bfgs %d xk [%f] dfk [%f] fk %f\n', 0, xk(1), ...
                dfk(1), fk)
    end

    for n = 1:max_it
        if norm(dfk,1) < gtol
            % gradient sufficiently small
            if disp, fprintf('norm gfk < gtol'), end
            break
        end
        if (dfk*dfk')/(df0*df0') < tol
            % gradient sufficiently small compared to original
            if disp, fprintf('rel gfk/gfk0 < gtol'), end
            break
        end

        if pk*dfk' >= 0
            warning('pk not in a descent direction')
            pk = -pk;
        end

        lambdak = opt_line_search(fun, xk, pk, dfk, fk);
        if lambdak < 0
            warning('parameter out of bounds!')
            break
        end

        xkp1 = xk + lambdak * pk;
        sk   = xkp1 - xk;
        if dfun_in_fun, [fkp1 dfkp1] = fun(xkp1);
        else fkp1 = fun(xkp1); dfkp1 = dfun(xkp1);
        end

        yk = dfkp1 - dfk;

        if fk-fkp1 < tol && n>5
            warning('function decrease less than tolerance')
            break
        end

        if abs(fk-fkp1) < tol * abs(fk) && n>10
            warning('function decrease less than RELATIVE tolerance')
            break
        end


        if yk*sk' == 0
            error('numerical error detected!')
            break
        end

        rhok = 1/(yk*sk');
        if rhok > 0
            % Hk will still be PSD because rho>0
            Hk = (eye(N)-[sk'*yk]*rhok)*(Hk*(eye(N)-[yk'*sk]*rhok))+sk'*sk*rhok;
        end

        xk  = xkp1;
        fk  = fkp1;
        dfk = dfkp1;
        pk = -dfk*Hk';

        xhist = [xhist; xk];
        fhist = [fhist; fk];

        if disp
            if length(xk) > 1
                fprintf('min_bfgs %d xk [%f;%f] dfk [%f;%f] fk %f\n', n, xk(1), xk(2), ...
                        dfk(1), dfk(2), fk)
            else
                fprintf('min_bfgs %d xk [%f] dfk [%f] fk %f\n', n, xk(1), ...
                        dfk(1), fk)
            end
        end
    end
end
