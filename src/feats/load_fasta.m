function [fastainfo ign] = load_fasta(filename)
%LOAD_FASTA loads FASTA file given by FILENAME and parses
%  it into a struct FASTAINFO.

    % Line format regular expressions for header, sequence, sstructure
    header_fmt = '^\s*>[(]?([\w-]+)(?:[|,\s].+)?\s*$';
    sequence_fmt = '^\s*([GCAUTgcaut]+)\s*$';
    structure_fmt = '^\s*([.()]+)(\s+\((\s*-?[0-9.]+)\s*\))?\s*$';
    multiloop_fmt = '[.(]+\)[.()]*\([.)]+';
    free_energy_fmt  = '^>.*\sFREE_ENERGY\s+([-\d.]+)\s.*$'; %Xue datasets

    % Open file and create output struct
    fastainfo = struct();
    ign = [];
    fid = fopen(filename);
    if fid < 0, error('unable to read file: %s', filename); end

    % Loop over lines
    k = 0; lc = 0;
    while ~feof(fid)
        lc = lc+1;
        % Read current line
        l = fgetl(fid);
        % Match against header format
        if regexp(l, header_fmt)
            % Initialize new entry
            k = k+1;
            groups = regexp(l,header_fmt, 'tokens');
            fastainfo(k).id = groups{1}{1};
            fastainfo(k).header = strtrim(l);
            fastainfo(k).beginline = lc;
            % Save previous example last line
            if k>1, fastainfo(k-1).endline = lc-1; end
            fastainfo(k).sequence = '';
            fastainfo(k).structure = '';
            fastainfo(k).free_energy = [];
            % Try to find free energy in header line (Xue specific)
            if regexp(l,free_energy_fmt)
                groups = regexp(l,free_energy_fmt, 'tokens');
                fastainfo(k).free_energy = sscanf(groups{1}{1},'%f');
            end
        % Match sequence format
        elseif regexp(l,sequence_fmt)
            groups = regexp(l,sequence_fmt, 'tokens');
            % Append to current sequence
            fastainfo(k).sequence = [fastainfo(k).sequence groups{1}{1}];
        % Match secondary structure format
        elseif regexp(l,structure_fmt)
            groups = regexp(l,structure_fmt, 'tokens');
            % Append to secondary structure
            fastainfo(k).structure = [fastainfo(k).structure groups{1}{1}];
            if length(groups{1}) > 2,
                fastainfo(k).free_energy = sscanf(groups{1}{3},'%f');
            end
        else
            warning('line %d of fasta file is ignored')
            ign(end+1) = lc;
        end

    end
    fastainfo(k).endline = lc;
    fclose(fid);

    % Try to obtain secondary structure information if not given
    warnonce = true;
    for k = 1:length(fastainfo)
        if length(fastainfo(k).structure) < 1 || isempty(fastainfo(k).free_energy)
            if warnonce
                warning(['Input file %s is missing secondary structure information. ' ...
                         'Prediction of secondary structure with Matlab may take ' ...
                         'considerable amount of time.'], filename)
                warnonce = false;
            end
            try
                [bracket,energy] = myrnafold(fastainfo(k).sequence);
                fastainfo(k).structure = bracket;
                fastainfo(k).free_energy = energy;
            catch e
                warning(['Secondary structure could not be computed. ' ...
                         'Neither Vienna RNA Toolkit nor Bioinformatics toolbox was found on your system.'])
                break
            end
        end
    end

    % Find multiloop entries
    for k = 1:length(fastainfo)
        fastainfo(k).multiloop = false;
        if regexp(fastainfo(k).structure, multiloop_fmt)
            fastainfo(k).multiloop = true;
        end
    end

end
