function [fastainfo ign] = load_fasta(filename)

    header_fmt = '^\s*>[(]?([a-zA-Z0-9]{2,3}[\w<.:/_+-]+)([|,\s].+)?\s*$';
    sequence_fmt = '^\s*([GCAUTgcaut]+)\s*$';
    structure_fmt = '^\s*([.()]+)(\s+\((\s*-?[0-9.]+)\s*\))?\s*$';
    multiloop_fmt = '[.(]+\)[.()]*\([.)]+';
    free_energy_fmt  = '^>.*\sFREE_ENERGY\s+([-\d.]+)\s.*$';

    fastainfo = struct();
    ign = [];
    fid = fopen(filename);

    k  = 0; lc = 0;
    while ~feof(fid)
        lc = lc+1;
        l = fgetl(fid);
        if regexp(l, header_fmt) % line matches header format
            k = k+1;
            groups = regexp(l,header_fmt, 'tokens');
            fastainfo(k).id = groups{1}{1};
            fastainfo(k).header = strtrim(l);
            fastainfo(k).beginline = lc;
            if k>1, fastainfo(k-1).endline = lc-1; end
            fastainfo(k).sequence = '';
            fastainfo(k).structure = '';
            fastainfo(k).free_energy = nan;
            if regexp(l,free_energy_fmt)
                groups = regexp(l,free_energy_fmt, 'tokens');
                fastainfo(k).free_energy = sscanf(groups{1}{1},'%f');
            end
        elseif regexp(l,sequence_fmt) % line matches sequence format
            groups = regexp(l,sequence_fmt, 'tokens');
            fastainfo(k).sequence = [fastainfo(k).sequence groups{1}{1}];
        elseif regexp(l,structure_fmt) % line matches structure format
            groups = regexp(l,structure_fmt, 'tokens');
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

    % find multiloop entries
    for k = 1:length(fastainfo)
        fastainfo(k).multiloop = false;
        if regexp(fastainfo(k).structure, multiloop_fmt)
            fastainfo(k).multiloop = true;
        end
    end

end