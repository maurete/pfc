function [kder, kval] = kernel_rbf_unc_deriv(u,v,gamma,varargin)
    [kval, kder] = kernel_rbf_unc(u,v,gamma);
end