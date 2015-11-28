function [kder, kval] = kernel_rbf_deriv(u,v,gamma,varargin)
%KERNEL_RBF_DERIV Radial Basis Function kernel derivative function.
%
%  [KDER, KVAL] = KERNEL_RBF_DERIV(U,V,GAMMA,...) Computes the derivative of
%  the RBF kernel for input matrices U and V. GAMMA is the spread parameter of
%  the RBF function, any other input argument is ignored.
%
%  See also KERNEL_RBF.

    [kval, kder] = kernel_rbf(u,v,gamma);

end
