function [out,all_sp] = loadset(name,species,id)
%LOADSET Load existing dataset with pre-computed features
%
%   OUT = LOADSET(NAME,SPECIES,ID) loads dataset NAME to be found
%     in ../data/ directory, for selectad SPECIES.
%     NAME is the dataset directory name, relative to ../data/.
%     SPECIES can be either 'all', 'human', 'non-human', or a cell
%     array of strings for each individual species.
%     OUT is a numeric matrix in which rows are entries, columns
%     1-66 being features, column 67 the entry class, column 68
%     the entry number (within respective species), column 69 the
%     species file number (in ascending order within dataset), and
%     column 70 the ID argument, or zero.
%
%   [OUT,NAMES] = LOADSET(...)
%     Optional second output argument is a cell array of strings
%     with the names of species files (excluding extension) present
%     in the dataset, with indexes matching the 69th column of OUT.
%
%   See also PROBLEM_GEN

    if nargin < 3 || isempty(id),      id=0;          end
    if nargin < 2 || isempty(species), species='all'; end

    % Validate dataset name
    if ~isdir(['../data/',name])
        error('loadset: invalid database name.')
    end

    % List all species in dataset
    bpath = ['../data/' name '/'];
    % List every .c file
    d = dir( [bpath '*.c'] );
    sp = { d.name }';
    % Strip .c extension to get all species in dataset
    all_sp = cellfun(@(in)in(1:end-2),sp,'UniformOutput',false);

    % Select species
    sel_sp = zeros(size(all_sp));
    if isstr(species)
        % Species argument is a string
        if strcmpi(species,'all')
            % Match all species
            sel_sp = ones(size(all_sp));
        elseif strcmpi(species,'human')
            % Match 'hsa' species file
            sel_sp = strcmpi(all_sp,'hsa');
        elseif strcmpi(species,'non-human')
            % Match all but 'hsa' species
            sel_sp = 1-strcmpi(all_sp,'hsa');
        end
    elseif iscell(species)
        % Species argument is a cell string
        for k=1:length(species)
            % Match respective species
            sel_sp = sel_sp + strcmpi(all_sp,species(k));
            % TODO fail on non-existent species?
        end
    end

    % Output array
    out = [];

    % Loop for all available species in dataset
    for j=1:length(all_sp)

        % If current species was selected
        if sel_sp(j)
            % Read files
            feat3 = dlmread([bpath,all_sp{j},'.3'], '\t');
            featx = dlmread([bpath,all_sp{j},'.3x'],'\t');
            feats = dlmread([bpath,all_sp{j},'.s'], '\t');
            featf = dlmread([bpath,all_sp{j},'.f'], '\t');
            class = dlmread([bpath,all_sp{j},'.c'], '\t');

            % Append to output matrix
            out = [ out;                        ... % current content
                    feat3, featx, feats, featf, ... % feature vector
                    class,                      ... % class
                    [1:length(class)]',         ... % entry number
                    j*ones(size(class)),        ... % species number
                    id*ones(size(class))         ]; % identifier
        end
    end
end
