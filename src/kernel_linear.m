function [K der] = kernel_linear(u,v,varargin)
    K = (u*v');
    der = [];
end
