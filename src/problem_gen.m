function prob = problem_gen(data_spec, varargin)
%PROBLEM_GEN Generate classification problem.
%
%  PROBLEM = PROBLEM_GEN(DATA_SPEC) generates a classification problem
%  according to DATA_SPEC. DATA_SPEC can be either
%    * A string with any of the values 'xue', 'ng' or 'batuwita': loads a
%      preset problem, 'xue' replicates the classification problem from [1],
%      'ng' generates a problem similar to that presented in [2], and
%      'batuwita' generates a similar problem to the one introduced in [3].
%    * A cell array with elements in sequence {SOURCE,CLASS,RATIO,...}, where
%        SOURCE is the source for the data, a string which contains either
%        a filename to a FASTA-formatted file or the name of a directory from
%        the SAMPLE_DATA directory as defined in CONFIG,
%        CLASS is the dataset class, can be zero or nan for testing datasets
%        where the class is unknown, and
%        PROPORTION is the proportion of train-to-test elements for that
%        data source: 0.85 means 85%/15% train/test, 1 implies the source
%        should be used only for training, 0 only for testing, or [123 456]
%        means 123 elements should be used for training and 456 for testing.
%
%  PROBLEM = PROBLEM_GEN(DATA_SPEC, OPTIONS) sets additional options for the
%  problem definition. OPTIONS is either a cell array or a comma-separated
%  sequence of options. Allowed options are:
%    * 'CVPartitions', <INTEGER> : sets the number of partitions for cross-
%        validation training (see help for STPART),
%    * 'CVRatio', <FLOAT> : the ratio of validation elements in each cross-
%        validation partition (see help for STPART),
%    * 'Balanced' or 'MLP' : tells the program to oversample the minority class
%        in order to avoid majority-class bias in MLP training (default false),
%    * 'Symmetric' : indicates that feature vectors should be normalized
%        to the [-1,1] range instead of the default [0,1],
%    * 'NoVerbose' : suppresses standard output,
%    * 'Scaling', <2-BY-NFEATS-ARRAY> : fixes feature scaling according to the
%        provided array, in which the first row contains the factor to multiply
%        each feature and the second row the offset to be applied for every
%        feature,
%    * <SCALAR INTEGER> : sets the random seed for shuffling the data, and
%    * <PROBLEM STRUCT> : extracts the scaling information from the provided
%        problem structure.
%
%  A somewhat complex invocation for this function could be
%  PROBLEM = PROBLEM_GEN( { 'mirbase82-mipred/multi', 1, [200 123], ...
%                           'coding', -1, [400 8094] }, ...
%                         'Balanced', 'CVPartitions', 8, 12345, OTHER_PROBLEM);
%  The returned problem would have thus 400 (oversampled) elements of the
%  positive class and 400 elements from the negative class for training, with
%  8 cross-validation partitions, shuffled with the random seed 12345, and
%  normalized according to the scaling information present in the OTHER_PROBLEM
%  struct. The testing set of this problem would be composed by 123 elements of
%  the positive class and 8094 of the negative class.
%
%  See also SCALE_DATA, SCALE_SYM, BALANCE_DATASET, STPART, PROBLEM_CLASSIFY.
%

    if nargin < 1, error('Must specify data to be loaded.'), end

    % set default options
    cv_parts = 10;
    cv_ratio = 0.1;
    balanced = false;
    symmetric = false;
    randseed = 1135;
    verbose = true;
    scaleinfo = false;
    f = nan;
    s = nan;

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
           elseif strcmpi(opts{i},'MLP')
               balanced = true;
           elseif strcmpi(opts{i},'Symmetric')
               symmetric = true;
           elseif strcmpi(opts{i},'NoVerbose')
               verbose = false;
           elseif strcmpi(opts{i},'Scaling')
               scaleinfo = true;
               i = i+1;
               f = opts{i}(1,:);
               s = opts{i}(2,:);
           end
       elseif isnumeric(opts{i})
           randseed = opts{i};
       elseif isstruct(opts{i})
           scaleinfo = true;
           f = opts{i}.scaling(1,:);
           s = opts{i}.scaling(2,:);
       end
       i = i+1;
    end

    % load known sample problems
    if isstr(data_spec)
        % set data_spec to known problem
        if strcmpi(data_spec,'xue')
            data_spec = { ...
                'mirbase50/3svm-train', 1, 1, ...
                'coding/3svm-train', -1, 1, ...
                'mirbase50/3svm-test', 1, 0, ...
                'coding/3svm-test', -1, 0 ...
                        };
        elseif strcmpi(data_spec,'ng')
            data_spec = { ...
                'mirbase82-mipred:hsa', 1, [200 123], ...
                'coding', -1, [400 246], ...
                        };
        elseif strcmpi(data_spec,'batuwita')
            data_spec = { ...
                'mirbase12-micropred:hsa', 1, 0.85, ...
                'coding', -1, [1078 7416], ... % 1174*8494/9248
                'other-ncrna', -1, [96 658] ... % 754*8494/9248
                        };
        elseif strcmpi(data_spec,'xue-updated')
            data_spec = { ...
                'mirbase50/3svm-train', 1, 1, ...
                'coding/3svm-train', -1, 1, ...
                'updated', 1, 0, ...
                        };
        elseif strcmpi(data_spec,'xue-conserved-hairpin')
            data_spec = { ...
                'mirbase50/3svm-train', 1, 1, ...
                'coding/3svm-train', -1, 1, ...
                'conserved-hairpin', -1, 0, ...
                        };
        elseif strcmpi(data_spec,'xue-cross-species')
            data_spec = { ...
                'mirbase50/3svm-train', 1, 1, ...
                'coding/3svm-train', -1, 1, ...
                'cross-species', 1, 0, ...
                        };
        elseif strcmpi(data_spec,'ng-ie-nh')
            data_spec = { ...
                'mirbase82-mipred:hsa', 1, [200 0], ...
                'coding', -1, [400 0], ...
                ['mirbase82-mipred:aga,age,ame,ath,bta,', ...
                 'cbr,cel,cfa,dme,dps,dre,ebv,fru,gga,gma,hcmv,', ...
                 'hsv1,kshv,lca,lla,mghv,mml,mmu,mtr,oar,osa,', ...
                 'ppt,ptc,ptr,rlcv,rno,sbi,sla,sof,ssc,sv40,', ...
                 'tni,xla,xtr,zma'], 1, 0, ...
                        };
        elseif strcmpi(data_spec,'ng-ie-nc')
            data_spec = { ...
                'mirbase82-mipred:hsa', 1, [200 0], ...
                'coding', -1, [400 0], ...
                'functional-ncrna', -1, 0, ...
                        };
        elseif strcmpi(data_spec,'xue-mirbase21')
            data_spec = { ...
                'mirbase50/3svm-train', 1, 1, ...
                'coding/3svm-train', -1, 1, ...
                'mirbase21:hsa', 1, 0, ...
                        };
        elseif strcmpi(data_spec,'ng-mirbase21')
            data_spec = { ...
                'mirbase82-mipred:hsa', 1, [200 0], ...
                'coding', -1, [400 0], ...
                'mirbase21:hsa', 1, 0, ...
                        };
        elseif strcmpi(data_spec,'batuwita-mirbase21')
            data_spec = { ...
                'mirbase12-micropred:hsa', 1, [587 0], ...
                'coding', -1, [1078 0], ...
                'other-ncrna', -1, [96 0] ...
                'mirbase21:hsa', 1, 0, ...
                        };
        elseif strcmpi(data_spec,'delta-mirbase21')
            data_spec = { ...
                'mirbase20:hsa', 1, 1, ...
                'coding', -1, [2990 0], ...
                'other-ncrna', -1, [754 0], ...
                'mirbase21-diff:hsa', 1, 0, ...
                        };
        else
           error('Unknown dataset name specified: %s.', data_spec)
        end
    end


    trainset = [];
    testset  = [];
    sources  = {};

    % set scaling function
    scalefun = @scale_norm;
    if symmetric, scalefun = @scale_sym; end

    % load data by scanning data_spec
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
            % try to read known sample data
            [data,meta] = loadset(name, species, id);
            data(:,67) = data_spec{i+1};

            % save dataset name:species name
            idx = unique(data(:,69));
            sources{id} = {};
            sources{id} = cellfun(@(s)[name,':',s],meta,'UniformOutput',false);

        catch e
            if ~any(strfind(e.message,'invalid database name'))
                rethrow(e)
            end

            % if data in unknown then treat name as a fasta file name
            addpath('./feats');

            [fasta ign] = load_fasta(name);
            % if numel(ign) > 0
            %     warning('Some entries have been ignored from file %s', ...
            %             in.filename);
            % end

            feat3 = feats_triplet(fasta);
            featx = feats_extra(fasta);
            feats = feats_sequence(fasta);
            featf = feats_structure(fasta);
            len = size(feat3,1);
            assert(all([[size(featx,1),size(feats,1),size(featf,1)]==len]), ...
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

        % shuffle the data within this source and append to train/test
        data = stshuffle(randseed,data);
        trainset = [trainset; data(1:n_train,:)];
        testset  = [testset;  data(n_train+1:n_train+n_test,:)];

        % reset data before next iteration
        data = [];
        id = id+1;

    end

    if size(trainset,1) == 0 && ~scaleinfo
        warning(['No scaling information supplied for test-only problem. ', ...
                 'Unless your data is normalized, test results will be ', ...
                 'invalid.'])
    end

    % shuffle training data between all sources
    trainset = stshuffle(randseed,trainset);

    % balance dataset if requested
    if balanced, [trainset,~] = balance_dataset(trainset, trainset(:,67)); end

    % build output structure
    prob = struct();

    prob.sources = sources;

    prob.traindata   = trainset(:,1:66);
    prob.trainlabels = trainset(:,67);
    prob.trainids    = trainset(:,68:70);

    [part.train,part.validation] = stpart(randseed, size(trainset,1), ...
                                          cv_parts, cv_ratio);
    prob.partitions = part;

    prob.randseed = randseed;
    prob.scaling = [f;s];

    prob.testdata   = testset(:,1:66);
    prob.testlabels = testset(:,67);
    prob.testids    = testset(:,68:70);

    if verbose
        npart = size(prob.partitions.train,2);
        nreal = sum(prob.trainlabels>0);
        npseu = sum(prob.trainlabels<0);

        [tidx,~] = find(prob.partitions.train);
        [vidx,~] = find(prob.partitions.validation);
        train_all  = round(numel(prob.trainlabels(tidx))/npart);
        train_real = round(sum(prob.trainlabels(tidx)>0)/npart);
        train_pseu = round(sum(prob.trainlabels(tidx)<0)/npart);
        valid_all  = round(numel(prob.trainlabels(vidx))/npart);
        valid_real = round(sum(prob.trainlabels(vidx)>0)/npart);
        valid_pseu = round(sum(prob.trainlabels(vidx)<0)/npart);

        fprintf(['> training set:      \t\t%d total\t%d real\t%d pseudo\n',...
                 '> %d cross validation partitions\n', ...
                 '> train partitions:     \t%d total\t%d real\t%d pseudo\n',...
                 '> validation partitions:\t%d total\t%d real\t%d pseudo\n',...
                 '>\n> test set:     \t\t%d total\t%d real\t%d pseudo\n'], ...
                numel(prob.trainlabels), nreal, npseu, npart, ...
                train_all, train_real, train_pseu, ...
                valid_all, valid_real, valid_pseu, ...
                numel(prob.testlabels), sum(prob.testlabels>0), ...
                sum(prob.testlabels<0));
    end

end
