function [xk, fk, xhist, fhist] = min_bfgs_simple ( fun, dfun, x0, tol, max_it )

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

    if isrow(df0), df0 = df0'; end
    
    % param history to watch for convergence
    xhist = x0;
    fhist = f0;
    
    Hk = eye(length(x0));
    xk = x0;
    fk = f0;
    dfk = df0;

    sk =  2*gtol;
    pk = -Hk*dfk;

    if length(xk) > 1
        fprintf('min_bfgs %d xk [%f;%f] dfk [%f;%f] fk %f\n', 0, xk(1), xk(2), ...
                dfk(1), dfk(2), fk)
    end
    
    for n = 1:max_it
        if norm(dfk,1) < gtol
            % gradient sufficiently small
            fprintf('norm gfk < gtol')
            break
        end
        if (dfk'*dfk)/(df0'*df0) < tol
            % gradient sufficiently small compared to original
            fprintf('rel gfk/gfk0 < gtol')
            break
        end
        
        if pk'*dfk >= 0
            warning('pk not in a descent direction')
            pk = -pk;
        end
        
        %lastf = rmfunc(thk);

        lambdak = line_search(fun, xk, pk, dfk, fk);
        if lambdak < 0
            warning('parameter out of bounds!')
            break
        end
        
        xkp1 = xk + lambdak * pk;
        sk   = xkp1 - xk;
        if dfun_in_fun, [fkp1 dfkp1] = fun(xkp1);
        else fkp1 = fun(xkp1); dfkp1 = dfun(xkp1);
        end
        if isrow(dfkp1), dfkp1 = dfkp1'; end
        yk = dfkp1 - dfk;
        
        if fk-fkp1 < tol && n>10
            warning('function decrease less than tolerance (1e-6)')
            break
        end
            
        if yk'*sk == 0
            error('numerical error detected!')
            break
        end
        
        rhok = 1/(yk'*sk);
        if rhok > 0
            % Hk will still be PSD because rho>0
            Hk = (eye(2)-[sk*yk']*rhok)*(Hk*(eye(2)-[yk*sk']*rhok))+sk*sk'*rhok; 
        end

        xk  = xkp1;
        fk  = fkp1;
        dfk = dfkp1;
        pk = -Hk*dfk;

        xhist = [xhist xk];
        fhist = [fhist fk];
        
        if length(xk) > 1
            fprintf('min_bfgs %d xk [%f;%f] dfk [%f;%f] fk %f\n', n, xk(1), xk(2), ...
                    dfk(1), dfk(2), fk)
        end
    end
end
