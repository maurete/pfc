function out = mlp_classify(net, input, threshold)
%MLP_CLASSIFY Perform classification with trained MLP model.
%
%  OUT = MLP_CLASSIFY(NET,INPUT) Classifies INPUT with given MLP network.
%  NET is a trained MLP network as returned by MLP_XTRAIN,
%  INPUT is a matrix where every row is considered a sample, and
%  THRESHOLD sets a minimum threshold magnitude for considering output class.
%
%  See also MLP_XTRAIN.

    if nargin < 3 || isempty(threshold), threshold = 0.1; end

    config; % Load global settings

    % Perform classification
    if isstruct(net)
        % libFANN case: assert libFANN functions are available
        if isempty(which('testFann')), addpath(FANN_DIR); end
        assert(~isempty(which('testFann')), 'Failed to load libFANN.')
        % Compute outputs
        out = testFann(net,input);
    else
        % Compute outputs
        out = net(input')';
    end

    % Generate output label vector
    if size(out,2) == 2
        % Two output neurons
        out = sign(round(out*[1;-1]/threshold));
    else
        % Single output neuron whose sign indicates class
        out = sign(out);
    end

end
