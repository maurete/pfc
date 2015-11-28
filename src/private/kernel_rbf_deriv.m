function [kder, kval] = kernel_rbf_deriv(u,v,gamma,varargin)
    [kval, kder] = kernel_rbf(u,v,gamma);
end