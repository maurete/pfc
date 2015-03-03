function [kval, deriv] = kernel_rbf_uni (x,y,C,gamma,varargin)
% modified SVM kernel as proposed by Adankon et al.
% our kernel function (Adankon & Cheriet, 2009)
%kfun = @(x,y,a,b) -exp( -a * norm(x-y,2)^2 + b);
% where a is roughly equivalent to 1/sigma^2 (or \gamma)
% and b=ln(C) is included inside the kernel function.
% In our training should set C=Inf and instead handle it 
% inside the kernel with param b
    if nargin == 2 || isempty(C), C = 1; gamma = 1; end
    if nargin == 3, gamma = C(2); C = C(1); end
    kval = exp( log(C(1)) - gamma(1) * ( repmat(sqrt(sum(x.^2,2).^2),1,size(y,1) )...
                                   -2*(x*y') + repmat(sqrt(sum(y.^2,2)'.^2),size(x,1),1)));        

    if nargout > 1,
        deriv = cat(3, kval, ...
                    - (repmat(sqrt(sum(x.^2,2).^2),  1, size(y,1) ) -2*(x*y') + ...
                       repmat(sqrt(sum(y.^2,2)'.^2), size(x,1),1) ) .* kval );
    end
end
