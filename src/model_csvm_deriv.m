function [deriv, output] = model_csvm_deriv(svmstruct,input,decision_values,...
                                            log_C,log_kargs)
%MODEL_CSVM_DERIV Compute derivatives of the SVM outputs w.r.t. hyperparameters
%
%  [DERIV,OUT] = MODEL_CSVM_DERIV(MODEL,INPUT,DECISION_VALUES,C_LOG,KPARAM_LOG)
%  Computes the derivative of the outputs w.r.t. the SVM 'C' parameter and
%  any additional kernel parameter. MODEL is the trained SVM model as returned
%  by MYSVM_TRAIN, INPUT contains the samples to be classified in rows,
%  DECISION_VALUES indicates (when true) that outputs should be the SVM
%  decision values or binary class predictions (when false),
%  C_LOG indicates wether to compute derivatives w.r.t. C in logarithmic space,
%  KPARAM_LOG tells wether to compute derivatives w.r.t. the kernel parameters
%  in logarithmic space.
%  DERIV is a matrix where the first row contains the derivatives of the output
%  w.r.t. C, and subsequent columns contain derivatives of the output w.r.t.
%  each kernel parameter.
%
%  The algorithm for computing the derivative w.r.t. C is taken from
%  Glasmachers, "Gradient Based Optimization of Support Vector Machines" (2008)
%  and Keerthi et al., "An Efficient Method for Gradient-Based Adaptation of
%  Hyperparameters in SVM Models" (2007). The implementation is largely
%  inspired by that of the Shark toolkit introduced in Igel et al., "Shark"
%  (YYYY) [http://shark-project.sourceforge.net].
%
%  See also MODEL_CSVM, MYSVM_TRAIN, MYSVM_CLASSIFY.

    if nargin < 5,       log_kargs = false; end
    if nargin < 4,           log_C = false; end
    if nargin < 3, decision_values = false; end
    [output, deriv] = model_csvm(svmstruct, input, decision_values, ...
                                 log_C, log_kargs);

end
