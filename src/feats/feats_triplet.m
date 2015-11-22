function feats = feats_triplet(fi)

    % fi is a fasta info struct as returned by load_fasta

    % extracted features:
    %  * 32 triplet count
    %

    N = length(fi);
    feats = nan(N,32);

    b = 'AGCU';
    s = '01'; % 0 => . (unpaired) ; 1 => () (paired)

    for i = 1:N
        if fi(i).multiloop, continue, end

        % find left- and rightmost occurrence of paired bases
        % in the left arm (ll,lr) and right arm (rl,rr)
        p = strfind(fi(i).structure, '(');
        ll = p(1); lr = p(end);
        p = strfind(fi(i).structure, ')');
        rl = p(1); rr = p(end);

        % valid because secondary structure is single-loop
        len = lr-ll + rr-rl + 2;

        sqn = upper(fi(i).sequence);
        % for the structure, replace '.' with 0 and (/) with 1s
        str = regexprep(fi(i).structure, '[()]', '1');
        str = strrep(str, '.', '0');

        % add extra padding character at each side if necessary
        if ll==1
            sqn = [' ' sqn]; str = ['0' str];
            ll = ll+1; lr = lr+1;
            rl = rl+1; rr = rr+1;
        end
        if rr==length(str)
            sqn = [sqn ' ']; str = [str '0'];
        end

        % initialize tr struct with fields matching each triplet
        tr = struct();
        tr.total = 0;
        % trn contains the ordered triplet names
        trn = {};
        for j=1:4, for k=1:2, for l=1:2, for m=1:2
                tr.([b(j),s(k),s(l),s(m)])=0;
                trn{end+1} = [b(j),s(k),s(l),s(m)];
        end, end, end, end

        % on both sides of the stem, count every triplet occurrence
        for j=[ll:lr,rl:rr]
            tr.([sqn(j) str(j-1:j+1)]) = tr.([sqn(j) str(j-1:j+1)]) + 1;
            tr.total = tr.total + 1;
        end

        % save scaled triplet count on ith row of feature matrix
        for j=1:length(trn)
            feats(i,j) = tr.(trn{j})/tr.total;
        end

    end

end
