function lambda = opt_line_search(f, x0, p, g, f0, sigma, lambda0, max_it, l_bound, u_bound)
% Bactracking bounded line search algorithm.
% Given function f, point x0, search direction p and gradient g,
% returns lambda such that
%   f(x0) - f(x0+lambda*p) >= sigma * lambda * p * g'
% with 0 < sigma < 1.
% Aditionally, lambda is restricted such that x+lambda*p
% lies between l_bound and u_bound.

    if nargin < 10, u_bound =  10*ones(size(x0)); end
    if nargin <  9, l_bound = -10*ones(size(x0)); end
    if nargin <  8, max_it  =    20; end
    if nargin <  7, lambda0 =     1; end
    if nargin <  6, sigma   =  1e-4; end

    % backtracking parameter
    tau = 0.5;

    ff = f;
    lambda = lambda0;
    if numel(x0) > 1 && iscolumn(x0),
        warning('x0 is column vector')
        x0 = x0'; p = p'; g = g'; ff = @(p) f(p');
    end
    if nargin < 5, f0 = ff(x0); end

    if any(size(x0) ~= size(p)) || any(size(p) ~= size(g))
        x0,p,g
        error('inconsistent size for point, direction and/or gradient')
    end
    assert(p*g'< 0, 'decrease not possible in direction p')

    % if xk is already out of bounds with further out, return -1
    if any(x0 > u_bound & p > 0) || any(x0 < l_bound & p < 0)
        warning('point x0 is out of bounds')
        lambda = -1;
        return
    end

    % make sure end x0 will lie between bounds
    while any(x0+lambda*p > u_bound) || any(x0+lambda*p < l_bound)
        lambda = lambda*tau;
    end

    % test for sufficient decrease while decreasing lambda
    t = -sigma*g*p';
    for i = 1:max_it
        try, fi = ff(x0+lambda*p);
        catch, fi = Inf;
        end

        if f0-fi >= lambda*t, return % success
        end

        lambda = lambda*tau;
    end

end
