function [train test] = load_datasets( dsets )

% the input parameter dsets is a struct array, each item
% specifying a dataset, with the following attributes:
%          .name: datset name (see valid_names below)
% .train_species: species that will be used for training. Can be
%                 any of 'human', 'non-human', 'all', or a cell
%                 array of strings with each species identifier,
%                 such as { 'hsa', 'rno', 'mmu' }. If this
%                 parameter is neither a string nor a cell array,
%                 nothing is loaded. Same for an unrecognized
%                 string value.
%  .test_species: species to be included in the test dataset. Same
%                 specification as train_species.
%   .train_ratio: how many elements will be included in the train
%                 set: 0=none, 1=all
%    .test_ratio: same as train_ratio above.
%   
% return values:
% two matrices, train and test, with the following columns
%  * 1:66: feature vector for entry: 3,3x,s,f
%  *   67: entry class
%  *   68: index in species file (== line no.)
%  *   69: index of species file in dataset (1 to M, in
%          alphabetical order => 'aaa'=1, 'zzz'=M)
%  *   70: dataset number ( as provided in the dsets struct)

    % valid dataset names
    valid_names = {     'coding'; 'functional-ncrna'; 'mirbase12'; ...
                   'other-ncrna'; 'updated';  'conserved-hairpin'; ...
                     'mirbase20'; 'mirbase50'; 'mirbase82-nr'};
    
    train = [];
    test  = [];

    for i=1:length(dsets)
        
        % validate dataset name
        val = strfind(valid_names, dsets(i).name);
        assert(sum([val{:,:}]) == 1, 'ERROR: invalid database name')
        
        % get dataset species
        bpath = ['../data/' dsets(i).name '/'];
        d = dir( [bpath '*.c'] ); sp = { d.name }';
        % strip the '.c' extension from species
        species = cellfun(@(in)in(1:end-2),sp,'UniformOutput',false);

        % find which species will be used for train/test
        trn_sp = zeros(size(species));
        tst_sp = zeros(size(species));
        
        if isstr(dsets(i).train_species)
            if strcmpi(dsets(i).train_species,'all')
                trn_sp = ones(size(trn_sp));
            elseif strcmpi(dsets(i).train_species,'human')
                trn_sp = strcmpi(species,'hsa');
            elseif strcmpi(dsets(i).train_species,'non-human')
                trn_sp = 1-strcmpi(species,'hsa');
            end
        elseif iscell(dsets(i).train_species)
            for k=1:length(dsets(i).train_species)
                trn_sp = trn_sp + strcmpi(species,dsets(i).train_species(k));
            end
        end
        
        if isstr(dsets(i).test_species)
            if strcmpi(dsets(i).test_species,'all')
                tst_sp = ones(size(tst_sp));
            elseif strcmpi(dsets(i).test_species,'human')
                tst_sp = strcmpi(species,'hsa');
            elseif strcmpi(dsets(i).test_species,'non-human')
                tst_sp = 1-strcmpi(species,'hsa');
            end
        elseif iscell(dsets(i).test_species)
            for k=1:length(dsets(i).test_species)
                tst_sp = tst_sp + strcmpi(species,dsets(i).test_species(k));
            end
        end
        
        cur_train = [];
        cur_test  = [];
        
        for j=1:length(species)
        
            feat3 = dlmread( [bpath species{j} '.3'], '\t' );
            featx = dlmread( [bpath species{j} '.3x'], '\t' );
            feats = dlmread( [bpath species{j} '.s'], '\t' );
            featf = dlmread( [bpath species{j} '.f'], '\t' );
            class = dlmread( [bpath species{j} '.c'], '\t' );
            
            num_train = round(length(class)*trn_sp(j)*dsets(i).train_ratio);
            num_test  = round(length(class)*trn_sp(j)*dsets(i).test_ratio);
            num_all   = num_train+num_test;
            
            shuf = randsample(length(class),num_all);

            cur_train = [ cur_train; ...
                          feat3(shuf(1:num_train),:) ... % feature vector
                          featx(shuf(1:num_train),:) ... % feature vector
                          feats(shuf(1:num_train),:) ... % feature vector
                          featf(shuf(1:num_train),:) ... % feature vector
                          class(shuf(1:num_train),:) ... % class
                          shuf(1:num_train)          ... % entry number
                          ones(size([1:num_train]')).*j ... % species number
                          ones(size([1:num_train]')).*i ... % dataset number
                        ];

            cur_test = [ cur_test; ...
                         feat3(shuf(num_train+1:num_all),:) ... % feature vector
                         featx(shuf(num_train+1:num_all),:) ... % feature vector
                         feats(shuf(num_train+1:num_all),:) ... % feature vector
                         featf(shuf(num_train+1:num_all),:) ... % feature vector
                         class(shuf(num_train+1:num_all),:) ... % class
                         shuf(num_train+1:num_all)          ... % entry number
                         ones(size([num_train+1:num_all]')).*j ... % species number
                         ones(size([num_train+1:num_all]')).*i ... % dataset number
                       ];
            
        end
        
        train = [ train; cur_train ];
        test  = [ test; cur_test ];
        
    end

end