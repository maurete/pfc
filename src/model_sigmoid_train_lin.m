function [params,err] = model_sigmoid_train_lin(out,targets,maxiter,tol,fail)
% MODEL_SIGMOID_TRAIN_LIN(out,targets,maxiter,tol,fail) implements
%  Platt's method for probabilistic output model fitting as proposed
%  on `A note on Platt’s probabilistic outputs for support vector
%  machines` by Hsuan-Tien Lin et al. (2007)
%

  % Input parameters:
  %   out = array of SVM outputs
  %   target = array of Booleans : is ith example a positive example?
  %   prior1 = number of positive examples
  %   prior0 = number of negative examples
  % Outputs:
  %   A, B = parameters of sigmoid

  if nargin < 5,     fail = false; end % raise error if no convergence
  if nargin < 4,      tol = 1e-10; end %
  if nargin < 3, maxiter = 200;   end

  % detect nan input
  if any(isnan(out))
      warning('NaN inputs to model_sigmoid_train_lin, expect invalid results.');
  end

  bintargets = [targets >=0];

  prior1 = sum(bintargets);
  prior0 = sum(~bintargets);

  % Parameter Setting
  maxiter = 100;    % maximum number of iterations
  minstep = 1e-10; % minimum step taken in line search
  sigma = 1e-3; % set to any value > 0

  % construct initial values: target supprot in array t, initial function
  % value in fval
  hiTarget = (prior1 + 1.0) / (prior1 + 2.0);
  loTarget = 1 / (prior0 + 2.0);
  len = prior0 + prior1; % Added by WSN.

  t = nan(1,len);
  t(bintargets) = hiTarget;
  t(~bintargets) = loTarget;

  A = 0;
  B = log((prior0 + 1.0)/(prior1 + 1.0));
  fval = 0.0;
  fApB = nan;

  for i = 1:len
    fApB = out(i)*A + B;
    if fApB >= 0
      fval = fval + t(i) * fApB + log(1.0 + exp(-fApB));
    else
      fval = fval + (t(i) - 1.0) * fApB + log(1.0+exp(fApB));
    end
  end

  for it = 1:maxiter
    % Update Gradient and Hessian (use H' = H + sigma I)
    h11 = sigma;
    h22 = sigma;
    h21 = 0.0;
    g1 = 0.0;
    g2 = 0.0;

    for i = 1:len
      fApB = out(i)*A + B;
      if fApB >= 0
	p = exp(-fApB)/(1.0 + exp(-fApB));
	q = 1.0/(1.0+exp(-fApB));
      else
	p = 1.0 / (1.0+exp(fApB));
	q = exp(fApB)/(1.0+exp(fApB));
      end
      d2 = p * q;
      h11 = h11 + out(i) * out(i) * d2;
      h22 = h22 + d2;
      h21 = h21 + out(i) * d2;
      d1 = t(i) - p;
      g1 = g1 + out(i) * d1;
      g2 = g2 + d1;
    end

    if (( abs(g1) < 1e-5 ) && ( abs(g2) < 1e-5))
      break;
    end

    det = h11*h22 - h21*h21;
    dA = -(h22*g1 - h21*g2)/det;
    dB = -(-h21*g1 + h11*g2)/det;
    gd = g1*dA + g2*dB;

    % line search
    stepsize = 1;
    while stepsize >= minstep
      newA = A + stepsize * dA;
      newB = B + stepsize * dB;
      newf = 0.0;
      %printf(STDERR "% Iter=%g newA=%g newB=%g\n", it, newA, newB);
      for i = 1:len
	fApB = out(i)*newA + newB;
	if fApB >= 0
	  newf = newf + t(i)*fApB+log(1+exp(-fApB));
	else
	  newf = newf + (t(i)-1)*fApB+log(1+exp(fApB));
	end
      end
      if newf < (fval + 0.0001*stepsize*gd)
	A = newA;
	B = newB;
	fval = newf;
	break;
      else
	stepsize = stepsize / 2.0;
      end
      if stepsize < minstep
	%printf(STDERR "Line Search Fails\n");
	break;
      end
    end
    if it >= maxiter
      fprintf('Reached maximum iterations (%d).\n', maxiter);
    end
  end

  params = [A,B];
