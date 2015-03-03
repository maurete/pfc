function lambda = line_search(f, xk, pk, gfk, fk, sigma, lambda0, max_it, l_bound, u_bound)

% Simple line search algorithm.
% Given function f, point xk, direction pk and gradient gfk,
% returns lambda such that
%   f(xk+lambda*pk) <= f(xk) + sigma * lambda * gfk' * pk
% with 0 < sigma < 1.
% Aditionally, lambda is restricted such that xk+lambda*pk
% lies between l_bound and u_bound.
    
    if nargin < 10, u_bound =  10*ones(size(xk)); end
    if nargin <  9, l_bound = -10*ones(size(xk)); end
    if nargin <  8, max_it  =    20; end
    if nargin <  7, lambda0 =     1; end
    if nargin <  6, sigma   =  1e-4; end
    if nargin <  5, fk      = f(xk); end

    % if xk is already out of bounds with further out, return -1
    if any(xk > 10 & pk > 0) || any(xk < -10 & pk < 0), lambda = -1; return, end

    % if pk is too big begin with lambda = 2/norm(pk)
    if lambda0 * norm(pk) > 2, lambda0 = 2/norm(pk); end
    
    % make sure end xk will lie between bounds (not really sure how it works)
    for i = 1:length(xk)
        if xk(i)+lambda0*pk(i) > u_bound(i), lambda0 = (u_bound(i)-xk(i))/pk(i); end
        if xk(i)+lambda0*pk(i) < l_bound(i), lambda0 = (l_bound(i)-xk(i))/pk(i); end
    end
    lambda = lambda0;
    
    % test for sufficient decrease while halving lambda
    for t = 1:max_it
        if f(xk+lambda*pk) <= fk + sigma*lambda*(gfk'*pk), return, end
        lambda = lambda/2;
    end
end