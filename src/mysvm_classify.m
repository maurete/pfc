function [labels dec_values] = mysvm_classify( model, samples )

    LIBSVM_DIR = './libsvm-3.20/matlab/';

    assert(size(samples,2) == size(model.sv_, 2),...
           'attempting to classify vectors with unknown length, SV length %d, requested %d', ...
           size(model.sv_, 2), size(samples, 2))

    if strncmpi(model.lib_, 'matlab', 6)
        if isempty(strfind(which('svmtrain'),'bioinfo')), rmpath(LIBSVM_DIR); end
        assert(any(strfind(which('svmtrain'),'bioinfo')), ...
               'mysvm_classify: failed to load Matlab bioinfo svmtrain.')

        % classify with matlab
        labels = svmclassify( model, samples);

    elseif strncmpi(model.lib_, 'libsvm', 6)
        if isempty(strfind(which('svmtrain'),'libsvm')), addpath(LIBSVM_DIR); end
        assert(any(strfind(which('svmtrain'),'libsvm')), ...
               'mysvm_train: failed to load libSVM svmpredict.')

        % remove _-ended structure fields
        f_ = fieldnames(model); lean = model;
        for i=1:length(f_), if f_{i}(end) == '_', lean=rmfield(lean,f_{i}); end, end

        % classify with libsvm
        [labels ign dv_libsvm] = svmpredict(zeros(size(samples,1),1), samples, lean, '-q');
    else
        error('Unknown svm library found in model')
    end

    if nargout < 2, return, end

    dec_values = model.kfunc_(samples,model.sv_,model.kparam_) * model.alpha_ - model.bias_;
    % if strncmpi(model.lib_, 'libsvm', 6)
    %     [dv_libsvm dec_values]
    % end
end