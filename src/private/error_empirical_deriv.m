function [deriv, err] = error_empirical_deriv(input, target)
%ERROR_EMPIRICAL_DERIV Find derivative of empirical risk according to the
%  "empirical error criterion" presented in Ayat et al., "Automatic model
%  selection for the optimization of SVM kernels" (2005) (with some tweaks).
%
%  See also ERROR_EMPIRICAL

    [err,deriv] = error_empirical(input, target);

end
