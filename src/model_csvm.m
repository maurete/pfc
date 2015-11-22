function [output, deriv] = model_csvm(svmstruct, input, decision_values, c_log, kparam_log)
    if nargin < 5,      kparam_log = false; end
    if nargin < 4,           c_log = false; end
    if nargin < 3, decision_values = false; end

    [output outputr] = mysvm_classify(svmstruct, input);
    if decision_values, output = outputr; end

    assert(all( sign(output) == sign(outputr) ), ...
           'sign(decision function) != svm output!')

    if nargout < 2, return, end

    % kernel function
    kfunc = svmstruct.kfunc_;
    if isstr(svmstruct.kfunc_), kfunc = str2func(svmstruct.kfunc_); end

    % number of parameters (C + kernel params)
    nparam = length(svmstruct.kparam_) + 1;

    % derivative for given inputs WRT (C, kernel params)
    deriv  = zeros(length(input), nparam );

    % (alpha, b) vector
    alphab = [ svmstruct.alpha_ ; svmstruct.bias_ ];
    alphab_deriv = zeros(length(alphab), nparam);

    % Free Support Vector + bias indices ( where abs(alpha) < C)
    fidx = [ find(~svmstruct.bsv_); length(alphab) ];

    % Bounded Support Vector indices ( where abs(alpha) = C)
    bidx = [ find(svmstruct.bsv_) ];

    % deriv for bounded SV is [label 0 0 0 ...]
    alphab_deriv(bidx) = svmstruct.svclass_(bidx);

    %% Find (\alpha,b) derivative for free SVs

    flen = length(fidx)-1; % free sv count (without bias)
    blen = length(bidx);

    H = zeros(flen+1);
    H_inv = zeros(flen+1);
    R = zeros(flen+1,blen);
    dH = zeros(flen+1, flen+1, nparam-1); % deriv only wrt kernel params
    dR = zeros(flen+1,   blen, nparam-1); % deriv only wrt kernel params

    % if there are free svs
    if flen > 0
        if nparam > 1
            % kernel has at least one parameter
            [H(1:flen,1:flen), dH(1:flen,1:flen,:)] = ...
                kfunc( svmstruct.sv_(fidx(1:flen),:), ...
                       svmstruct.sv_(fidx(1:flen),:), ...
                       svmstruct.kparam_ );

            if blen > 0
                % there are bounded svs
                [R(1:flen,:), dR(1:flen,:,:)] = ...
                    kfunc( svmstruct.sv_(fidx(1:flen),:), ...
                           svmstruct.sv_(bidx,:), ...
                           svmstruct.kparam_ );
            end
        else
            % kernel has no parameters: dH, dR will be empty
            H(1:flen,1:flen) = ...
                kfunc( svmstruct.sv_(fidx(1:flen),:), ...
                       svmstruct.sv_(fidx(1:flen),:), ...
                       svmstruct.kparam_ );
            if blen > 0
                R(1:flen,:) = ...
                    kfunc( svmstruct.sv_(fidx(1:flen),:), ...
                           svmstruct.sv_(bidx,:), ...
                           svmstruct.kparam_ );
            end
        end
    end

    H(flen+1,1:flen) = 1;
    H(1:flen,flen+1) = 1;
    if blen > 0, R(flen+1,:) = 1; end

    % invert Hessian
    H_inv = pinv(H,1e-10);

    % compute deriv of (alpha,b) wrt C
    if blen > 0
        alphab_deriv(fidx,1) = - H_inv * (R * svmstruct.svclass_(bidx));
    end
    %alphab_deriv(bidx(alphab(bidx)>0),1)  = 1;
    %alphab_deriv(bidx(alphab(bidx)<=0),1) = - 1;

    % compute deriv of (alpha, b) wrt kernel params
    for k=1:nparam-1
        alphab_deriv(fidx,k+1) = -( H_inv * (dH(:,:,k)*alphab(fidx)+dR(:,:,k)*alphab(bidx)) );
    end

    % find derivatives of inputs wrt params (C, kernelparams)
    ninput = size(input,1);
    nsv    = svmstruct.nsv_;
    Kaux   = ones(ninput,nsv+1);
    dKaux  = zeros(ninput,nsv,nparam-1);
    if nparam > 1
        % kernel has at least one parameter
        [Kaux(:,1:nsv), dKaux] = ...
            kfunc( input, ...
                   svmstruct.sv_, ...
                   svmstruct.kparam_ );
    else
        % kernel has no parameters
        Kaux(:,1:nsv) = ...
            kfunc( input, ...
                   svmstruct.sv_, ...
                   svmstruct.kparam_ );
    end

    deriv = Kaux * alphab_deriv;
    for k=1:nparam-1
        deriv(:,k+1) = deriv(:,k+1) + dKaux(:,:,k) * alphab(1:nsv);
    end

    % if searching for optimal C in logspace, multiply by C
    if c_log, deriv(:,1) = deriv(:,1) .* svmstruct.C_; end
    % if searching for optimal kernel params in logspace
    if kparam_log, deriv(:,2:nparam) = deriv(:,2:nparam) * diag(svmstruct.kparam_); end

end