function [obj,beta,idx,model] = opt_rsquared(K,tolkkt,cache_size)
%OPT_RSQUARED R^2 optimization function
%
%  [OBJ,BETA,IDX,MODEL] = OPT_RSQUARED(K,TOLKKT,CACHE_SIZE,LIBSVM_PATH)
%  Trains a one-class SVM model on the kernel matrix K and returns a
%  coefficient vector BETA that maximizes the problem
%      f = 1 - beta'* K *beta
%      subject to beta >= 0 and sum(beta) = 1.
%  OBJ contains the value of f, and IDX the indices of support vectors for
%  which beta_i != 0. MODEL is the trained SVM model.
%  Optional input arguments are TOLKKT, the SVM precision and CACHE_SIZE the
%  cache size for the SVM training algorithm.
%
%  This function is auxilliary to the RMB model selection method.
%
%  Please note that this function requires the libSVM training function.
%
%  See also ERROR_RMB_CSVM, SELECT_MODEL_RMB.

    if nargin < 3, cache_size = 200; end
    if nargin < 2, tolkkt = 1e-6; end

    config; % load libSVM path

    % check wether to remove libsvm path from environment after execution
    rm_libsvm_path = false;
    if isempty(strfind(which('svmtrain'),'libsvm'))
        rm_libsvm_path = true;
        addpath(LIBSVM_DIR);
    end

    % make sure we will be using libsvm's svmtrain and not Matlab's own
    assert(any(strfind(which('svmtrain'),'libsvm')), ...
           'opt_squared: failed to load libSVM library.')

    len = size(K,1);

    % setup and train one-class LibSVM problem
    K1 = [ [1:len]' K ];
    model = svmtrain( ones(len,1), K1, [ '-t 4 -s 2' ...
                        ' -n ' num2str(1/len) ...
                        ' -e ' num2str(tolkkt) ...
                        ' -m ' num2str(cache_size) ...
                        ' -q ' ] );

    idx = model.sv_indices;
    beta = model.sv_coef;
    obj = 1 - model.sv_coef' * K(idx,idx) * model.sv_coef;
    % Chung's libsvm hack: obj = 1-2*obj

    if rm_libsvm_path, rmpath(libsvm_path); end

end
