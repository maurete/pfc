function model = model_csvm_train(lib, kfun, samples, labels, boxconstraint, kfun_param, ...
                              autoscale, tolkkt, prob_estimates, unconstrained, varargin)

    if nargin < 10, unconstrained = false; end
    if nargin < 9; prob_estimates = false; end
    if nargin < 8; tolkkt         = 1e-6;  end
    if nargin < 7; autoscale      = false; end
    if nargin < 6; kfun_param     = [];    end
    if nargin < 5; boxconstraint  = 1;     end

    if unconstrained
        model = mysvm_train( lib, kfun, samples, labels, exp(boxconstraint), kfun_param, ...
                             autoscale, tolkkt, prob_estimates );
    else
        model = mysvm_train( lib, kfun, samples, labels, boxconstraint, kfun_param, ...
                             autoscale, tolkkt, prob_estimates );
    end

end