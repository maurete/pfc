function [AB] = model_sigmoid_train_lin( outputs, labels )

    len = length(labels);

    % Initial parameters
    A = 0;
    B = log((sum(labels<0)+1)/(sum(labels>0)+1));

    % Targets
    t_i = zeros(len,1);
    % positive and negative targets, use this instead of 0,1
    % for reference see Platt, eqs 12, 23
    tpos = (sum(labels>0)+1)/(sum(labels>0)+2);
    tneg = 1/(sum(labels<0)+2);
    t_i(labels>0) = tpos;
    t_i(labels<0) = tneg;

    % Classifier outputs
    f_i = outputs;

    % convergence constants
    maxiter = 100;
    minstep = 1e-10;
    sigma   = 1e-12;
    epsilon = 1e-5;

    %F = - sum( (f_i.*A+B)-t_i.*(f_i.*A+B) -log( exp(f_i.*A+B)+1),1)
    % at this point fi*A+B is always > 0
    F = sum( t_i.*(f_i.*A+B) + log(1+exp(-(f_i.*A+B))) );

    for it=1:maxiter
        G = zeros(2,1);
        H = zeros(2,2);

        fApB = f_i.*A+B;

        p_i = zeros(size(fApB));
        q_i = zeros(size(fApB));

        p_i(fApB>=0) = exp(-fApB(fApB>=0))./(1+exp(-fApB(fApB>=0)));
        q_i(fApB>=0) = (1+exp(-fApB(fApB>=0))).^-1;
        p_i(fApB<0)  = (1+exp(fApB(fApB<0))).^-1;
        q_i(fApB<0)  = exp(fApB(fApB<0))./(1+exp(fApB(fApB<0)));

        %p_i = (1+exp(f_i*A+B)).^(-1);
        %one_minus_p_i = exp(f_i.*A+B)./(exp(f_i.*A+B)+1);

        G(1) = f_i' * (t_i-p_i);
        G(2) = sum ( t_i-p_i );

        H(1,1) = (f_i.^2)' * (p_i .* q_i);
        H(2,2) = p_i' * q_i;
        H(1,2) = f_i' * (p_i .* q_i);
        H(2,1) = H(1,2);
        H = H + (sigma * eye(2));

        if norm(G,Inf)<epsilon
            %warning('While fitting model, exiting early due to gradient being too small.')
            AB = [A B];
            return
        end

        detH = det(H);

        % solve [dA;dB] = inv(H+lambda*I)*G manually
        H_inv = [ H(2,2), -H(1,2); -H(2,1), H(2,2) ] ./ detH;
        delta = H_inv * (-G); % note negative gradient

        gdescent = G'*delta;

        % Line search
        alpha = 1;
        while alpha >= minstep % do line search
            newA = A + alpha*delta(1);
            newB = B + alpha*delta(2);

            %newF = - sum( (f_i.*newA+newB)-labels.*(f_i.*newA+newB) -log( exp(f_i.*newA+newB)+1),1);
            %newF = - sum( (f_i.*newA+newB)-t_i.*(f_i.*newA+newB) -log( exp(f_i.*newA+newB)+1),1)

            fApB = f_i.*newA+newB;
            newF = sum( t_i(fApB>=0).*fApB(fApB>=0)+log(1+exp(-fApB(fApB>=0))) );
            newF = newF + sum( (t_i(fApB<0)-1).*fApB(fApB<0)+log(1+exp(fApB(fApB<0))) );

            % Check for sufficient decrease
            if newF < F+0.0001*alpha*gdescent
                A = newA;
                B = newB;
                F = newF;
                break % sufficient decrease satisfied
            end
            alpha = alpha/2;
            if alpha < minstep
                warning('While doing line search, minimum step condition fails, exiting early.')
                break
            end
        end

    end % for

    if it >= maxiter
        warning('Maximum number of iterations reached without convergence in model fitting.')
    end

    AB = [A B];

end