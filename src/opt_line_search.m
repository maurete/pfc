function [lambda,neval] = opt_line_search(f, x0, p, g, f0, sigma, lambda0, ...
                                          max_it, l_bound, u_bound)
%OPT_LINE_SEARCH Bounded bactracking line search algorithm.
%
%  [LAMBDA,NE] = OPT_LINE_SEARCH(F,X0,P,G) finds the maximum scale in direction
%  P where a decrease in function value is found. F is a handle to the function
%  to minimize, X0 the starting point, P the direction vector, and G the
%  gradient of F at X0.
%
%  [LAMBDA,NE] = OPT_LINE_SEARCH(F,X0,P,G,F0,SIGMA,LAMBDA0,MAX_IT,LB,UB)
%  performs line search with additional parameters: F0 is the function value at
%  point X0, SIGMA is the control parameter (default: 1e-4), LAMBDA0 is the
%  starting value for LAMBDA, MAX_IT the maximum number of iterations, LB is
%  the lower bound (in domain space) considered for the search, and UB is the
%  upper bound. LB and UB delimit an hypercube within which the search is
%  performed, its default values are -10 and 10 respectively in each dimension.
%
%  The backtracking line search algorithm can be described like this:
%  Given a function f, point x0, search direction p and gradient g, find lambda
%  such that
%      f(x0) - f(x0+lambda*p) >= sigma * lambda * p * g', and
%      l_bound < x+lambda*p < u_bound (in every dimension),
%  with 0 < sigma < 1.
%

    if nargin < 10 || isempty(u_bound), u_bound =  10*ones(size(x0)); end
    if nargin <  9 || isempty(l_bound), l_bound = -10*ones(size(x0)); end
    if nargin <  8 || isempty(max_it),  max_it  =    20; end
    if nargin <  7 || isempty(lambda0), lambda0 =     1; end
    if nargin <  6 || isempty(sigma),   sigma   =  1e-4; end

    % backtracking parameter
    tau = 0.5;

    % number of function evaluations
    neval = 0;

    % aux function handle
    ff = f;

    % set current lambda
    lambda = lambda0;

    % find function value at x0 if not given
    if nargin <  5 || isempty(f0), f0 = ff(x0); neval = neval+1; end

    % assert points are row vectors
    if numel(x0) > 1 && iscolumn(x0),
        warning('x0 is column vector')
        x0 = x0'; p = p'; g = g'; ff = @(p) f(p');
    end

    % assert x0, p and g have the same size
    if any(size(x0) ~= size(p)) || any(size(p) ~= size(g))
        x0, p, g
        error('inconsistent size for point, direction and/or gradient')
    end

    % assert p is indeed a descent direction
    assert(p*g'< 0, 'decrease not possible in direction p')

    % if x0 is already out of bounds with p pointing further out, return -1
    if any([ [x0 > u_bound & p > 0], [x0 < l_bound & p < 0] ])
        warning('point x0 is out of bounds')
        lambda = -1;
        return
    end

    % make sure resulting point will lie between bounds & lambda is not too big
    while any( [[x0+lambda*p>u_bound],[x0+lambda*p<l_bound],norm(lambda*p)>4] )
        lambda = lambda*tau;
    end

    % main loop
    t = -sigma*g*p';
    for i = 1:max_it
        % eval function at x0+lambda*p ...
        try
            fi = ff(x0+lambda*p);
            neval = neval + 1;
        catch, fi = Inf;
        end

        % ... if function decreases at that point, exit successfully, ...
        if f0-fi >= lambda*t, return, end

        % ... else, scale down lambda and continue
        lambda = lambda*tau;
    end

end
