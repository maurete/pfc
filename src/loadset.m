function [out] = loadset( name, species, id )

%% Loadset - Loads named dataset by species
    
% input:
%     name: dataset name (see valid_names below)
%      spc: species to load. possible values:
%            'all' - loads all samples
%            'human' - loads human samples only
%            'non-numan' - non-human samples only
%            { 'sp1', 'sp2', ... } - select species
%                by listing them in a cell array
%       id: identifier to be added as last column,
%           to be used for sample tracing
%
% output matrix with 69 columns:
%     1-66: feature vector:
%             1-32 - triplet features (.3)
%            33-36 - triplet-extra features (.3x)
%            37-59 - sequence features (.s)
%            60-66 - folding features (.f)
%       67: entry class (1, 0 or -1)
%       68: index in species file (== line no.)
%       69: index of species file in dataset (1 to M, in
%           alphabetical order => 'aaa'=1, 'zzz'=M)

    % valid dataset names
    valid_names = {     'coding'; 'functional-ncrna'; 'mirbase12'; ...
                   'other-ncrna'; 'updated';  'conserved-hairpin'; ...
                     'mirbase20'; 'mirbase50'; 'mirbase82-nr'; ...
                   'mirbase20-nr' };
    
    % validate dataset name
    val = strfind(valid_names, name);
    assert(sum([val{:,:}]) == 1, 'ERROR: invalid database name')
        
    % get available species in dataset
    bpath = ['../data/' name '/'];
    d = dir( [bpath '*.c'] );
    sp = { d.name }';
    % strip the '.c' extension from species
    all_sp = cellfun(@(in)in(1:end-2),sp,'UniformOutput',false);

    % find which species will be returned
    sel_sp = zeros(size(all_sp));
        
    % generate 'selected species' vector
    if isstr(species)
        if strcmpi(species,'all')
            sel_sp = ones(size(all_sp));
        elseif strcmpi(species,'human')
            sel_sp = strcmpi(all_sp,'hsa');
        elseif strcmpi(species,'non-human')
            sel_sp = 1-strcmpi(all_sp,'hsa');
        end
    elseif iscell(species)
        for k=1:length(species)
            sel_sp = sel_sp + strcmpi(all_sp,species(k));
        end
    end
    
    % output array
    out = [];
    
    % loop for all available species in dataset
    for j=1:length(all_sp)
        
        % if current species was selected
        if sel_sp(j)
            feat3 = dlmread( [bpath all_sp{j} '.3'], '\t' );
            featx = dlmread( [bpath all_sp{j} '.3x'], '\t' );
            feats = dlmread( [bpath all_sp{j} '.s'], '\t' );
            featf = dlmread( [bpath all_sp{j} '.f'], '\t' );
            class = dlmread( [bpath all_sp{j} '.c'], '\t' );
        
            out = [ out;                        ... % current content
                    feat3, featx, feats, featf, ... % feature vector
                    class,                      ... % class
                    [1:length(class)]',         ... % entry number
                    j*ones(size(class)),        ... % species number
                    id*ones(size(class))         ]; % identifier
        
        end        
    end
end