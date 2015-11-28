function [kval,kder] = kernel_rbf(u,v,gamma,varargin)
%KERNEL_RBF Radial Basis Function kernel function.
%
%  [KVAL,KDER] = KERNEL_RBF(U,V,GAMMA,...) Computes the RBF kernel matrix for
%  the input matrices U and V. GAMMA is the spread parameter of the RBF
%  function, any other input argument is ignored. The RBF function is
%     K(u,v) = exp(-gamma * ||u-v||^2)
%  KDER is the derivative of the kernel w.r.t. the gamma parameter
%     dK(u,v)/dgamma = -||u-v||^2 * exp(-gamma * ||u-v||^2)
%
%  See also KERNEL_LINEAR.

    if nargin < 3 || isempty(gamma), gamma = 1; end
    if size(u,1) < 1 || size(v,1) < 1, kval = []; kder = []; return, end

    % Compute kernel matrix
    kval = exp(-gamma(1)*( repmat(sqrt(sum(u.^2,2).^2),1,size(v,1) )...
                        -2*(u*v') + repmat(sqrt(sum(v.^2,2)'.^2),size(u,1),1)));

    % Compute derivative if requested
    if nargout > 1
        kder = - ( repmat(sqrt(sum(u.^2,2).^2),  1, size(v,1) ) -2*(u*v') + ...
                   repmat(sqrt(sum(v.^2,2)'.^2), size(u,1),1) ) .* kval;
    end

end
