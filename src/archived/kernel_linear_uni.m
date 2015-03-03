function K = kernel_linear_uni(u,v,C,varargin)
% Linear kernel for the unified framework:
% K(x,y) = a * dot(x,y) where a = C (GUESS)
    K = C(1)*(u*v');
end
