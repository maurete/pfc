function feats = feats_structure(fi)

    % fi is a fasta info struct as returned by load_fasta

    N = length(fi);
    feats = nan(N,7);

    p  = {'AU', 'UA', 'GC', 'CG', 'UG', 'GU'};
    pc = struct();

    for i = 1:N

        str = fi(i).structure;
        sqn = upper(fi(i).sequence);

        bp = numel(strfind(str,'('));
        assert(bp == numel(strfind(str,')')), ...
               'Could not correctly match base pairs');

        for j=1:6, pc.(p{j}) = 0; end
        pc.total = 0;

        s = [];
        for j=1:length(str)
           if str(j) == '.', continue
           elseif str(j) == '('
               % push
               s(end+1) = sqn(j);
           elseif str(j) == ')'
               % pop
               v = s(end);
               s = s(1:end-1);
               pc.([v sqn(j)]) = pc.([v sqn(j)]) + 1;
               pc.total = pc.total + 1;
           else
               throw MException('invalid character found in structure');
           end
        end

        AU = pc.AU+pc.UA;
        GC = pc.GC+pc.CG;
        GU = pc.GU+pc.UG;

        assert(pc.total == bp, 'found base pairings different from bp');

        mfe = fi(i).free_energy;
        if isnan(mfe)
            throw MException(['No free energy information found in struct. Please fold the sequences with RNAFold and try again.']);
        end

        l = length(str);
        gc = numel(strfind(sqn,'G'))+numel(strfind(sqn,'C'));
        pgc = 100*gc/l;
        mfei1 = mfe/(l*pgc);
        mfei4 = mfe/bp;

        feats(i,1) = mfe;
        feats(i,2) = mfei1;
        feats(i,3) = mfei4;
        feats(i,4) = bp/l;
        feats(i,5) = AU/l;
        feats(i,6) = GC/l;
        feats(i,7) = GU/l;

    end

end