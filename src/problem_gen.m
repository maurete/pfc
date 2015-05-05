function prob = problem_gen(data_spec, varargin)

    if nargin < 1, error('Must specify data to be loaded.'), end

    % set default options
    cv_parts = 10;
    cv_ratio = 0.1;
    balanced = false;
    symmetric = false;
    randseed = 1135;
    verbose = true;

    % check if options are passed as a cell array
    opts = varargin;
    nopts = numel(varargin);
    if numel(varargin) == 1 && numel(varargin) > 0 && iscell(varargin{1})
        opts = varargin{1};
        nopts = numel(opts);
    end

    % parse options
    i=1;
    while i <= nopts
       if ischar(opts{i})
           if strcmpi(opts{i},'CVPartitions')
               i = i+1;
               cv_parts = opts{i};
           elseif strcmpi(opts{i},'CVRatio')
               i = i+1;
               cv_ratio = opts{i};
           elseif strcmpi(opts{i},'Balanced')
               balanced = true;
           elseif strcmpi(opts{i},'Symmetric')
               symmetric = true;
           elseif strcmpi(opts{i},'NoVerbose')
               verbose = false;
           end
       elseif isnumeric(opts{i})
           randseed = opts{i};
       end
       i = i+1;
    end

    % load data
    if isstr(data_spec)
        % set data_spec to known problem
        if strcmpi(data_spec,'xue')
            data_spec = { ...
                'mirbase50/3svm-train', 1, 1, ...
                'mirbase50/3svm-test', 1, 0, ...
                'coding/3svm-train', -1, 1, ...
                'coding/3svm-test', -1, 0 ...
                        };
        elseif strcmpi(data_spec,'ng')
            data_spec = { ...
                'mirbase82-mipred/multi', 1, [200 123], ...
                'coding', -1, [400 8094], ...
                        };
        elseif strcmpi(data_spec,'batuwita')
            data_spec = { ...
                'mirbase12-micropred/multi', 1, 0.85, ...
                'coding', -1, [1012 7482], ...
                'other-ncrna/multi', -1, [118 19] ...
                        };
        else
           error('Unknown dataset name specified: %s.', data_spec)
        end
    end

    trainset = [];
    testset  = [];
    sources  = {};

    s = nan; f = nan;
    scalefun = @scale_data;
    if symmetric, scalefun = @scale_sym; end

    % load data
    id = 1;
    for i=1:3:numel(data_spec)
        sp1 = textscan(data_spec{i},'%s','delimiter',':');
        name = sp1{1}{1};
        species = 'all';
        data = [];

        if numel(sp1{1}) > 1
            sp2 = textscan(sp1{1}{2},'%s','delimiter',',');
            species = sp2{1};
        end
        try
            % try to read known data
            [data,meta] = loadset(name, species, id);

            % save dataset name:species name
            idx = unique(data(:,69));
            sources{id} = {};
            sources{id} = cellfun(@(s)[name,':',s],meta,'UniformOutput',false);

        catch e
            % treat name as a filename
            addpath('./feats');

            [fasta ign] = load_fasta(name);
            % if numel(ign) > 0
            %     warning('Some entries have been ignored from file %s',in.filename);
            % end

            feat3 = feats_triplet(fasta);
            featx = feats_extra(fasta);
            feats = feats_sequence(fasta);
            featf = feats_structure(fasta);
            len = size(feat3,1);
            assert(size(featx,1)==len&&size(feats,1)==len&&size(featf,1)==len, ...
                   'Unexpected error extracting features!')

            class = data_spec{i+1};
            data = [ feat3, featx, feats, featf, ...
                     ones(len,1)*class, [fasta(:).beginline]', ...
                     zeros(len,1), ones(len,1)*id ];

            sources{id} = name;
        end

        % normalize data
        if isnan(f), [~,f,s] = scalefun(data(:,1:66)); end
        data(:,1:66) = scalefun(data(:,1:66),f,s);

        % partition data into train/test sets
        part_spec = data_spec{i+2};
        n_train = 0;
        n_test = 0;
        n_elem = size(data,1);
        if numel(part_spec) > 1
            n_train = part_spec(1); n_test = part_spec(2);
        else
            n_train = round(part_spec*n_elem);
            n_test  = round((1-part_spec)*n_elem);
        end

        data = stshuffle(randseed,data);
        trainset = [trainset; data(1:n_train,:)];
        testset  = [testset;  data(n_train+1:n_train+n_test,:)];

        % reset data before next iteration
        data = [];
        id = id+1;
    end

    trainset = stshuffle(randseed,trainset);
    if balanced
        [trainset,~] = balance_dataset(trainset, trainset(:,67));
    end

    % build output structure
    prob = struct();

    prob.traindata   = trainset(:,1:66);
    prob.trainlabels = trainset(:,67);
    prob.trainids    = trainset(:,68:70);

    [part.train part.validation] = stpart(randseed, size(trainset,1), cv_parts, cv_ratio);
    prob.partitions = part;

    prob.randseed = randseed;

    prob.testdata   = testset(:,1:66);
    prob.testlabels = testset(:,67);
    prob.testids    = testset(:,68:70);

    % print information @TODO enhance this information
    if verbose
        npart = size(prob.partitions.train,2);
        nreal = sum(prob.trainlabels>0);
        npseu = sum(prob.trainlabels<0);

        [tidx,~] = find(prob.partitions.train);
        [vidx,~] = find(prob.partitions.validation);
        train_real = round(sum(prob.trainlabels(tidx)>0)/npart);
        train_pseu = round(sum(prob.trainlabels(tidx)<0)/npart);
        valid_real = round(sum(prob.trainlabels(vidx)>0)/npart);
        valid_pseu = round(sum(prob.trainlabels(vidx)<0)/npart);

        fprintf(['> cv partitions\t%d\n#\n', ...
                 '# dataset\tsize\t#train\t#test\n', ...
                 '# -------\t----\t------\t-----\n', ...
                 '> real\t\t%d\t%d\t%d\n', ...
                 '> pseudo\t%d\t%d\t%d\n#\n' ], ...
                npart, nreal, train_real, valid_real, ...
                npseu, train_pseu, valid_pseu);
    end

end