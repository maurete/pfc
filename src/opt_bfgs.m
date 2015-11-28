function [xk,fk,xhist,fhist,neval] = opt_bfgs (fun,dfun,x0,tol,max_it,disp)
%OPT_BFGS BFGS (Broyden–Fletcher–Goldfarb–Shanno) optimization algorithm
%
%  [XK,FK,XHIST,FHIST,NEVAL] = OPT_BFGS(FUN,DFUN,X0,TOL,MAX_IT,DISP) minimizes
%  the function FUN with the BFGS algorithm.
%  FUN is a handle to a function which accepts a row vector representing a
%  point in R^N and returns a single scalar value as first output argument, and
%  optionally the gradient of the function at that point as second output.
%  DFUN is a handle to a function which receives a row vector representing a
%  point in R^N and returns the gradient of the function a that point. DFUN can
%  be empty if the gradient is already returned by FUN as second output arg.
%  X0 is the starting point for the search.
%  MAX_IT is the maximum number of iterations (defaults to 100).
%  DISP indicates wether to print information, true by default.
%  XK is the point where the minimum is found, and FK the value at that point.
%  XHIST and FHIST is the sequence of points evaluated and their values.
%  NEVAL is the number of function evaluations.
%
%  This method is a reimplementation in MATLAB of the one found in the
%  "optimize.py" file by Travis E. Oliphant, part of SciPy http://scipy.org
%

    if nargin < 6, disp = true; end
    if nargin < 5, max_it =  100; end
    if nargin < 4, tol    = 1e-6; end

    if ~isa(dfun, 'function_handle'), dfun_in_fun = true;
    else dfun_in_fun = false;
    end

    % print functions
    function info(varargin), if disp, fprintf(varargin{:}); end, end
    vfmt = @(vec) sprintf('%s\b',sprintf('% f,',vec));

    % gradient norm tol
    gtol = tol*length(x0);

    % evaluate starting point
    if dfun_in_fun, [f0,df0] = fun(x0);
    else, f0 = fun(x0); df0 = dfun(x0);
    end

    % number of function evaluations
    neval = 1;

    % param history to watch for convergence
    xhist = x0;
    fhist = f0;

    % number of dimensions
    N = numel(x0);
    % Hessian
    Hk = eye(N);
    % current point
    xk = x0;
    % current function value
    fk = f0;
    % current gradient
    dfk = df0;
    % current step size
    sk =  2*gtol;
    % current direction
    pk = -dfk*Hk';

    info('# min_bfgs %d xk [%s] dfk [%s] fk %f\n', 0, vfmt(xk), vfmt(dfk), fk);

    % main loop
    for n = 1:max_it

        % check for convergence by gradient magnitude
        if norm(dfk,1)<gtol
            info('# stop condition: gfk < gtol\n'); break
        end
        if (dfk*dfk')/(df0*df0') < tol
            info('# stop condition: gfk/gfk0 < gtol\n'); break
        end

        % check that pk points to a descent direction
        if pk*dfk' >= 0
            warning('pk not in a descent direction')
            pk = -pk; %
        end

        % find a lower-valued point via line search
        [lambdak,ne] = opt_line_search(fun, xk, pk, dfk, fk);
        if lambdak < 0
            warning('parameter out of bounds, aborting\n')
            break
        end

        % set next search point and evaluate function value and gradient
        xkp1 = xk + lambdak * pk;
        sk   = xkp1 - xk;
        if dfun_in_fun, [fkp1,dfkp1] = fun(xkp1);
        else fkp1 = fun(xkp1); dfkp1 = dfun(xkp1);
        end
        % count number of function evaluations
        neval = neval+ne+1;

        % gradient difference
        yk = dfkp1 - dfk;

        if n > 5
            % check for convergence by function decrease
            if fk-fkp1 < tol
                info('# stop cond: function decrease less than tolerance\n')
                break
            end
            if abs(fk-fkp1) < tol * abs(fk)
                info('# stop: fun decrease less than relative tolerance\n')
                break
            end
        end

        % update Hessian
        rhok = min(1/(yk*sk'),1000);
        if rhok > 0
            % Hk will still be PSD because rho>0
            Hk=(eye(N)-[sk'*yk]*rhok)*(Hk*(eye(N)-[yk'*sk]*rhok))+sk'*sk*rhok;
        end

        % update variables for next iteration
        xk  = xkp1;
        fk  = fkp1;
        dfk = dfkp1;
        pk = -dfk*Hk';

        % save point and function value history
        xhist = [xhist; xk];
        fhist = [fhist; fk];

        info('# min_bfgs %d xk [%s] dfk [%s] fk %f\n',n,vfmt(xk),vfmt(dfk),fk);

    end

end
