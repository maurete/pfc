function [deriv, kval] = kernel_rbf_uni_deriv (x,y,C,gamma,varargin)
    if nargin == 2 || isempty(C), C = 1; gamma = 1; end
    if nargin == 3, gamma = C(2); C = C(1); end
    [kval, deriv] = kernel_rbf_uni(x, y, C, gamma);
end
