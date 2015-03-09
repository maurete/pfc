function prob = load_problem( dataset, featset, npart, ratio, randseed, symmetric, info)

    if nargin < 7 || isempty(info), info = true; end
    if nargin < 6 || isempty(symmetric), symmetric = false; end
    if nargin < 5 || isempty(randseed), randseed = 1135; end
    if nargin < 4, ratio = []; end
    if nargin < 3, npart = []; end

    com = common();
    features = com.featindex{featset};

    [data.train data.test] = load_data(dataset, randseed, symmetric);
    trainset = com.stshuffle(randseed,[data.train.real;data.train.pseudo]);

    prob = struct();
    prob.trainset = trainset(:,features);
    prob.trainlabels = trainset(:,67);

    [part.train part.validation] = stpart(randseed, size(trainset,1), npart, ratio);
    prob.partitions = part;

    prob.npartitions = size(part.train,2);

    prob.test = data.test;

    prob.dataset = dataset;
    prob.featureset = featset;
    prob.featindex = features;

    prob.randseed = randseed;

    if info
        npart = prob.npartitions;
        nreal = sum(prob.trainlabels>0);
        npseu = sum(prob.trainlabels<0);

        [tidx,~] = find(prob.partitions.train);
        [vidx,~] = find(prob.partitions.validation);
        train_real = round(sum(prob.trainlabels(tidx)>0)/npart);
        train_pseu = round(sum(prob.trainlabels(tidx)<0)/npart);
        valid_real = round(sum(prob.trainlabels(vidx)>0)/npart);
        valid_pseu = round(sum(prob.trainlabels(vidx)<0)/npart);

        fprintf('> dataset\t%s\n', dataset );
        fprintf('> featureset\t%d\t%s\n', featset, ...
                com.featname{featset});
        fprintf(['> cv partitions\t%d\n#\n', ...
                 '# dataset\tsize\t#train\t#test\n', ...
                 '# -------\t----\t------\t-----\n', ...
                 '> real\t\t%d\t%d\t%d\n', ...
                 '> pseudo\t%d\t%d\t%d\n#\n' ], ...
                npart, nreal, train_real, valid_real, ...
                npseu, train_pseu, valid_pseu);
    end

end