function feats = feats_extra(fi)

    % fi is a fasta info struct as returned by load_fasta

    % extracted features:
    %  * length3: main stem length
    %  * basepair:
    %  * gc_content:
    %  * len_bp_ratio:
    %

    N = length(fi);
    feats = nan(N,4);

    for i = 1:N
        if fi(i).multiloop, continue, end

        p = strfind(fi(i).structure, '(');
        ll = p(1); lr = p(end);
        p = strfind(fi(i).structure, ')');
        rl = p(1); rr = p(end);

        len = lr-ll + rr-rl + 2;
        feats(i,1) = len;

        bp = numel(strfind(fi(i).structure,'('));
        assert(bp == numel(strfind(fi(i).structure,')')), ...
               'Could not correctly match base pairs');
        feats(i,2) = bp;

        feats(i,3) = len/bp;

        gc_count = 0;
        gc_count = gc_count + numel(strfind(upper(fi(i).sequence(ll:lr)),'G'));
        gc_count = gc_count + numel(strfind(upper(fi(i).sequence(ll:lr)),'C'));
        gc_count = gc_count + numel(strfind(upper(fi(i).sequence(rl:rr)),'G'));
        gc_count = gc_count + numel(strfind(upper(fi(i).sequence(rl:rr)),'C'));

        feats(i,4) = gc_count/len;
    end


end