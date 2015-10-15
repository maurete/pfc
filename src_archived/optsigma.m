function [sigma inverse] = optsigma ( data, labels, tabfile, dataset, featset )

    if nargin < 5 featset = 0; end
    if nargin < 4 dataset = '?'; end
    if nargin < 3 tabfile = 'resultsigma'; end
    if nargin < 2
        labels = data(:,67);
        data = data(:,1:66);
    end

    com = common;

    idxpos = find(labels == 1);
    idxneg = find(labels < 1);

    sigmas = [0.001:0.001:0.009, 0.01:0.01:0.1, 0.15:0.05:0.5, 0.6:0.1:2, 2.5:0.5:10, 11:20, 25:5:50, 60:10:100, 200:50:500]; % 2.^[7:-0.5:-4];
                                                                                                                              %sigmas = logspace(-10,10, 100);
    result = zeros(size(sigmas));
    resul2 = zeros(size(sigmas));
    resnum = zeros(size(sigmas));
    resden = zeros(size(sigmas));

    pos = data(idxpos,:);
    neg = data(idxneg,:);

    N1 = numel(idxpos);
    N2 = numel(idxneg);

    com.init_matlabpool();

    parfor s = 1:length(sigmas)
        sig = sigmas(s);
        num = ((N1 - dblsum(sig, pos, pos)/N1) + ...
               (N2 - dblsum(sig, neg, neg)/N2));
        den = ( dblsum(sig, pos, pos) / (N1^2) + ...
                dblsum(sig, neg, neg) / (N2^2) - ...
                2*dblsum(sig, pos, neg) / (N1*N2));
        result(s) =  num/den;
        resul2(s) =  den/num;
        resnum(s) = num;
        resden(s) = den;
    end

    plot( log2(sigmas), result/max(abs(result)), 'b', ...
              log2(sigmas), resul2/max(abs(resul2)), 'r' ) %, ...
                                    %sigmas, resnum/max(abs(resnum)), 'c', ...
                                    %sigmas, resden/max(abs(resden)), 'm')

    sigma   = log2(sigmas( find(result==min(result), 1, 'first') ));
    inverse = log2(sigmas( find(resul2==max(resul2), 1, 'first') ));

    com.write_train_info(tabfile, dataset, featset, 'sigma-optim', ...
                         sigma, inverse, -1);

end
