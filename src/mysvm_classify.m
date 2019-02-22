function [labels,dec_values] = mysvm_classify(model,samples)
%MYSVM_CLASSIFY Classify samples using support vector machine model.
%
%   LABELS = MYSVM_CLASSIFY(MODEL,SAMPLES) classifies each row in
%     SAMPLES using the SVM model MODEL created using MYSVM_TRAIN and
%     returns the predicted class LABELS. SAMPLES must have the same
%     number of columns as the data used to train the classifier in
%     MYSVM_TRAIN. LABELS has the same number of rows as SAMPLES.
%
%   [~,DECISION_VALUES] = MYSVM_CLASSIFY(MODEL,SAMPLES) returns the
%     output of the SVM classifier in MODEL for each row in SAMPLES.
%     DECISION_VALUES are real-valued, thus they cannot be used
%     directly as a grouping variable, however, they're useful for
%     assessing the SVM decision function, such as fitting a posterior
%     probability model.
%
%   See also MYSVM_TRAIN

    config; % Load global settings

    % Validate input samples length
    assert(size(samples,2) == size(model.sv_,2), ...
           'Unmatched length: SVs have length %d, input samples %d.', ...
           size(model.sv_,2), size(samples,2));

    if strncmpi(model.lib_, 'matlab', 6)
        % If matlab classifier selected, remove libsvm from path
        vrsion = version('-release');
        if length(vrsion) == 0
            error('Matlab not detected!')
        elseif vrsion < 'R2013'
            if isempty(strfind(which('svmtrain'),'bioinfo')), rmpath(LIBSVM_DIR); end
            assert(any(strfind(which('svmtrain'),'bioinfo')), ...
                   'mysvm_classify: failed to load Matlab bioinfo svmtrain.')
        else
            if isempty(strfind(which('svmtrain'),'toolbox/stats')), rmpath(LIBSVM_DIR); end
            assert(any(strfind(which('svmtrain'),'toolbox/stats')), ...
                   'mysvm_classify: failed to load Matlab Statistics Toolbox'' svmtrain.')
        end

        % Classify with matlab
        labels = svmclassify(model,samples);

    elseif strncmpi(model.lib_, 'libsvm', 6)
        % If libsvm selected, assert it is loaded in path
        if isempty(strfind(which('svmtrain'),'libsvm')), addpath(LIBSVM_DIR); end
        assert(any(strfind(which('svmtrain'),'libsvm')), ...
               'mysvm_train: failed to load libSVM svmpredict.')

        % Remove _-ended structure fields for passing to svmpredict
        f_ = fieldnames(model); lean = model;
        for i=1:length(f_), if f_{i}(end) == '_', lean=rmfield(lean,f_{i}); end, end

        % Classify with libsvm
        [labels,~,dv] = svmpredict(zeros(size(samples,1),1), samples, lean, '-q');

    else
        % If svm library present in model is unknown, raise an error.
        error('Unknown SVM library found in model.')
    end

    % Don't compute decision values when not requested.
    if nargout < 2, return, end

    % Compute decision values by directly applying the kernel function to samples
    kfunc = model.kfunc_;
    if isstr(model.kfunc_), kfunc = str2func(model.kfunc_); end
    dec_values = kfunc(samples,model.sv_,model.kparam_) * model.alpha_ - model.bias_;

    % Compare dec_values with libsvm's decision values side by side
    % if strncmpi(model.lib_, 'libsvm', 6)
    %     [dv,dec_values]
    % end

end
