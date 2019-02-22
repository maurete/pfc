function out = cross_validation_inner_loop(p, problem, feats, args, ftrain, ...
                                           fcls, xtrain, do_deriv, fclsderiv)
% inner cross-validation loop

    trainset    = problem.traindata(problem.partitions.train(:,p),feats);
    valset      = problem.traindata(problem.partitions.validation(:,p),feats);
    trainlabels = problem.trainlabels(problem.partitions.train(:,p));
    vallabels   = problem.trainlabels(problem.partitions.validation(:,p));

    out = struct();
    out.status = 0;
    out.train_indexes = problem.partitions.train(:,p);
    out.validation_indexes = problem.partitions.validation(:,p);
    out.model = [];
    out.predictions = nan(size(valset,1),1);
    out.gradient = nan(size(valset,1),length(args));

    % Try training the model
    try
        % Do either classical training or x-training
        if xtrain, out.model = ftrain(trainset, trainlabels, valset, vallabels, args);
        else, out.model = ftrain(trainset, trainlabels, args);
        end

        % make predictions on validation set
        out.predictions = fcls(out.model, valset);

        if do_deriv
            % Find derivative of validation set w.r.t. every parameter
            out.gradient = fclsderiv(out.model, valset);
        end

    catch e
        % If training did not succeed for this partition
        % because of divergence, set error flag but keep going
        if any(strfind(e.identifier,'NoConvergence')) || ...
                any(strfind(e.identifier,'InvalidInput'))
            out.status = 1;
            warning(e.message)
        else
            % Rethrow any other kind of error
            rethrow(e);
        end
    end
end
