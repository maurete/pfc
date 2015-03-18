function feats = feats_triplet(fi)

    % fi is a fasta info struct as returned by load_fasta

    % extracted features:
    %  * 32 triplet count
    %

    N = length(fi);
    feats = nan(N,32);

    b = 'AGCU';
    s = '.(';

    for i = 1:N
        if fi(i).multiloop, continue, end

        p = strfind(fi(i).structure, '(');
        ll = p(1); lr = p(end);
        p = strfind(fi(i).structure, ')');
        rl = p(1); rr = p(end);

        len = lr-ll + rr-rl + 2;

        sqn = upper(fi(i).sequence);
        str = strrep(fi(i).structure, ')', '(');

        if ll==1
            sqn = [' ' sqn]; str = ['.' str];
            ll = ll+1; lr = lr+1;
            rl = rl+1; rr = rr+1;
        end
        if rr==length(str)
            sqn = [sqn ' ']; str = [str '.'];
        end

        % find triplets
        tr = struct();
        tr.total = 0;
        trn = {};
        for j=1:4, for k=1:2, for l=1:2, for m=1:2
                tr.([b(j),s(k),s(l),s(m)])=0;
                trn{end+1} = [b(j),s(k),s(l),s(m)];
        end, end, end, end

        for j=[ll:lr,rl:rr]
            tr.([sqn(j) str(j-1:j+1)]) = tr.([sqn(j) str(j-1:j+1)]) + 1;
            tr.total = tr.total + 1;
        end

        for j=1:length(trn)
                feats(i,j) = tr.(trn{j})/tr.total;
        end

    end


end