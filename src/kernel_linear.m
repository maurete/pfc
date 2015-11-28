function [K,der] = kernel_linear(u,v,varargin)
%KERNEL_LINEAR Linear kernel function.
%
%  [K,DER] = KERNEL_LINEAR(U,V,...) Computes the internal product of matrices
%  U and V. Extra arguments supplied are simply ignored. The DER output
%  argument is just an empty matrix.
%
%  See also KERNEL_RBF.

    K = (u*v');
    der = [];

end
