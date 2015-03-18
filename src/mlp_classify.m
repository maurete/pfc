function out = mlp_classify(net, input, delta)
%MLP_CLASSIFY Classify inputs with trained MLP network.
% OUT = MLP_CLASSIFY(NET,INPUT)
% Classifies input data applying given MLP network.
%
% PARAMETER      DESCRIPTION
%
% net            Trained MLP network as returned by MLP_TRAIN
%
% input          Matrix with rows corresponding to testing samples.
%
% delta          Minimum magnitude for considering output class.
%

    if nargin < 3 || isempty(delta), delta = 0.1; end

    if isstruct(net)
        FANN_DIR = './mfann/';
        if isempty(which('testFann')), addpath(FANN_DIR); end
        assert(~isempty(which('testFann')), ...
               'mlp_xtrain: failed to load FANN testFann.')
        out = testFann(net,input);
    else
        % Calculate outputs for given samples.
        out = net(input')';
    end
    % Generate [-1, +1] label vector
    if size(out,2) == 2
        out = sign(round(out*[1;-1]/delta));
    else
        out = sign(out);
    end
end
