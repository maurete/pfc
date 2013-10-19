function [feat lbl] = load_dataset( name, species )
%% Load Dataset
% loads dataset with name name
% if species is given as a cell array of strings,
% loads only specified species, otherwise loads all species
    
    % valid dataset names
    valid_names = {'coding'; 'functional-ncrna'; 'mirbase12'; ...
                   'other-ncrna'; 'updated'; 'conserved-hairpin'; ...
                   'mirbase20'; 'mirbase50'; 'mirbase82-nr'};
    
    % validate dataset name
    val = strfind(valid_names, name);
    assert(sum([val{:,:}]) == 1, 'ERROR: invalid database name')
    
    % dataset base path
    basepath = ['../data/' name '/'];
    
    file3 = [];
    filex = [];
    files = [];
    filef = [];
    filec = [];

    % if given a list of species...
    if nargin < 2
        % ...select all available ones
        species = {'*'};
    elseif isstr(species)
        species = { species };
    end
        
    % load features by species
    for j=1:length(species)
        file3 = [file3; dir([basepath species{j} '.3'])];
        filex = [filex; dir([basepath species{j} '.3x'])];
        files = [files; dir([basepath species{j} '.s'])];
        filef = [filef; dir([basepath species{j} '.f'])];
        filec = [filec; dir([basepath species{j} '.c'])];
    end
    
    % fun reads file into an array
    fun = @(file) dlmread([basepath file],'\t');

    % read feat array for each file
    feat3 = cellfun( fun, {file3.name},'UniformOutput',false);
    featx = cellfun( fun, {filex.name},'UniformOutput',false);
    feats = cellfun( fun, {files.name},'UniformOutput',false);
    featf = cellfun( fun, {filef.name},'UniformOutput',false);
    featc = cellfun( fun, {filec.name},'UniformOutput',false);
    
    % concatenate all features into one
    feat = cell2mat([feat3' featx' feats' featf']);
    lbl = cell2mat(featc');
