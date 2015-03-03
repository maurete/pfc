function [kval kder] = kernel_rbf(u,v,gamma,varargin)
% Standard RBF kernel in the form
% K(x,y) = exp( -gamma * ||x-y||^2 )
    if nargin < 3 || isempty(gamma), gamma = 1; end
    if size(u,1) < 1 || size(v,1) < 1, kval = []; kder = []; return, end

    % kernel matrix
    kval = exp(-gamma(1)*( repmat(sqrt(sum(u.^2,2).^2),1,size(v,1) )...
                        -2*(u*v') + repmat(sqrt(sum(v.^2,2)'.^2),size(u,1),1)));

    % return derivative wrt gamma if requested as second argument
    if nargout > 1
        kder = - ( repmat(sqrt(sum(u.^2,2).^2),  1, size(v,1) ) -2*(u*v') + ...
                   repmat(sqrt(sum(v.^2,2)'.^2), size(u,1),1) ) .* kval;
    end
end