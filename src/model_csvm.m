function [output, deriv] = model_csvm(svmstruct, input, decision_values, unconstrained)
    if nargin < 4, unconstrained = false; end
    if nargin < 3, decision_values = false; end

    [output outputr] = mysvm_classify(svmstruct, input);
    if decision_values, output = outputr; end

    assert(all( sign(output) == sign(outputr) ), ...
           'sign(decision function) != svm output!')

    if nargout < 2, return, end

    % number of parameters (C + kernel params)
    nparam = length(svmstruct.kparam_) + 1;

    % derivative for given inputs WRT (C, kernel params)
    deriv  = zeros(length(input), nparam );

    % (alpha, b) vector
    alphab = [ svmstruct.alpha_ ; svmstruct.bias_ ];
    alphab_deriv = zeros(length(alphab), nparam);

    % VERIFY these indices are correctly generated
    % Free Support Vector indices ( where abs(alpha) < C)
    fidx = [ find(~svmstruct.bsv_); length(alphab) ];
    %fidx = [ find([ abs(svmstruct.alpha_) < svmstruct.C_ ]); length(alphab) ];
    % Bounded Support Vector indices ( where abs(alpha) < C)
    bidx = [ find(svmstruct.bsv_) ];
    %bidx = find([ abs(svmstruct.alpha_) >= svmstruct.C_ ]);

    flen = length(fidx)-1; % free index count (without b)
    blen = length(bidx);

    H = zeros(flen+1);
    H_inv = zeros(flen+1);
    R = zeros(flen+1,blen);
    dH = zeros(flen+1, flen+1, nparam-1); % deriv only wrt kernel params
    dR = zeros(flen+1,   blen, nparam-1); % deriv only wrt kernel params
    if flen > 0
    if nparam > 1
        % kernel has at least one parameter
        [H(1:flen,1:flen), dH(1:flen,1:flen,:)] = ...
            svmstruct.kfunc_( svmstruct.sv_(fidx(1:flen),:), ...
                              svmstruct.sv_(fidx(1:flen),:), ...
                              svmstruct.kparam_ );
        if blen > 0
            [R(1:flen,:), dR(1:flen,:,:)] = ...
                svmstruct.kfunc_( svmstruct.sv_(fidx(1:flen),:), ...
                                  svmstruct.sv_(bidx,:), ...
                                  svmstruct.kparam_ );
        end
    else
        % kernel has no parameters: dH, dR will be empty
        H(1:flen,1:flen) = ...
            svmstruct.kfunc_( svmstruct.sv_(fidx(1:flen),:), ...
                              svmstruct.sv_(fidx(1:flen),:), ...
                              svmstruct.kparam_ );
        if blen > 0
            R(1:flen,:) = ...
                svmstruct.kfunc_( svmstruct.sv_(fidx(1:flen),:), ...
                                  svmstruct.sv_(bidx,:), ...
                                  svmstruct.kparam_ );
        end
    end
    end

    H(flen+1,1:flen) = 1;
    H(1:flen,flen+1) = 1;
    if blen > 0
        R(flen+1,:)  = 1;
    end

    H_inv = pinv(H,1e-10);

    % compute deriv of (alpha,b) wrt C
    if blen > 0
        alphab_deriv(fidx,1) = - H_inv * (R * svmstruct.svclass_(bidx));
        alphab_deriv(bidx(alphab(bidx)>0),1)  = svmstruct.cplus_/svmstruct.cminus_;
        alphab_deriv(bidx(alphab(bidx)<=0),1) = - svmstruct.cminus_/svmstruct.cplus_;
        % If exponential: VERIFY if this should be done or not
        if unconstrained,
            alphab_deriv(:,1) = alphab_deriv(:,1) .* svmstruct.C_; end
    end

    % compute deriv of (alpha, b) wrt kernel params
    for k=1:nparam-1
        %aux = dH(:,:,k) * alphab(fidx);
        %aux = aux + dR(:,:,k)*alphab(bidx);
        alphab_deriv(fidx,k+1) = -( H_inv * (dH(:,:,k)*alphab(fidx)+dR(:,:,k)*alphab(bidx)) );
        %if unconstrained, alphab_deriv(fidx,k+1) = alphab_deriv(fidx,k+1) .* svmstruct.kparam_(k); end
    end

    % find derivatives of inputs wrt params (C, kernelparams)
    ninput = size(input,1);
    nsv    = svmstruct.nsv_;
    Kaux   = ones(ninput,nsv+1);
    dKaux  = zeros(ninput,nsv,nparam-1);
    if nparam > 1
        % kernel has at least one parameter
        [Kaux(:,1:nsv), dKaux] = ...
            svmstruct.kfunc_( input, ...
                              svmstruct.sv_, ...
                              svmstruct.kparam_ );
    else
        % kernel has no parameters
        Kaux(:,1:nsv) = ...
            svmstruct.kfunc_( input, ...
                              svmstruct.sv_, ...
                              svmstruct.kparam_ );
    end

    % svmstruct.kfunc_
    % issparse(Kaux)
    % issparse(dKaux)
    % issparse(deriv)
    % issparse(alphab)

    deriv = Kaux * alphab_deriv;
    for k=1:nparam-1
        deriv(:,k+1) = deriv(:,k+1) + dKaux(:,:,k) * alphab(1:nsv);
    end

end