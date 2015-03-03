function [obj beta idx model] = Rsquared2( K, tolkkt, cache_size, libsvm_path )
% K is the computed kernel for all training vectors 

    if nargin < 4, libsvm_path = './libsvm-3.20/matlab/';
    if nargin < 3, cache_size = 200; end
    if nargin < 2, tolkkt = 1e-6; end
    
    rm_libsvm_path = false;
    if isempty(strfind(which('svmtrain'),'libsvm'))
        rm_libsvm_path = true;
        addpath(libsvm_path);
    end
    assert(any(strfind(which('svmtrain'),'libsvm')), ...
           'Rsquared2: failed to load libSVM library.')
    
    len = size(K,1);
    % setup one-class LibSVM problem
    K1 = [ [1:len]' K ];
    model = svmtrain( ones(len,1), K1, [ '-t 4 -s 2' ...
                        ' -n ' num2str(1/len) ...
                        ' -e ' num2str(tolkkt) ...
                        ' -m ' num2str(cache_size) ...
                        ' -q ' ] );
            
    idx = model.sv_indices;
    beta = model.sv_coef;
    obj = 1 - model.sv_coef' * K(idx,idx) * model.sv_coef;
    % chung libsvm hack = obj = 1-2*obj

    if rm_libsvm_path, rmpath(libsvm_path); end
end