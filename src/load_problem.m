function prob = load_problem( dataset, featset, npart, ratio, randseed, symmetric)

    if nargin < 6 || isempty(symmetric), symmetric = false; end
    if nargin < 5 || isempty(randseed), randseed = 1135; end
    if nargin < 4 || ratio = []; end
    if nargin < 3 || npart = []; end

    com = common;
    features = com.featindex{featset};

    [data.train data.test] = load_data(dataset, randseed, symmetric);
    trainset = com.stshuffle(randseed,[data.train.real;data.train.pseudo]);

    prob = struct();
    prob.trainset = trainset(:,features);
    prob.trainlabels = trainset(:,67);

    [part.train part.validation] = stpart(randseed, size(trainset,1), npart, ratio);
    prob.partitions = part;

    prob.test = data.test;

    prob.dataset = dataset;
    prob.featureset = featset;

end