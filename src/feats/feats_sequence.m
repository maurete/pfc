function feats = feats_sequence(fi)

    % fi is a fasta info struct as returned by load_fasta

    % extracted features:
    %  * length3: main stem length
    %  * basepair:
    %  * gc_content:
    %  * len_bp_ratio:
    %

    N = length(fi);
    feats = nan(N,23);

    idx = 'ACGU';

    for i = 1:N
        % sequence length
        feats(i,1) = length(fi(i).sequence);

        % find single nucleotide count
        for j = 1:4
            feats(i,j+1) = numel(strfind(fi(i).sequence,idx(j)));
        end

        % find dinucleotide count
        dn = struct();
        dnn = {};
        for j=1:4, for k=1:4,
                dn.([idx(j),idx(k)])=0; dnn{end+1} = [idx(j),idx(k)];
        end, end
        sqn = upper(fi(i).sequence);
        for j = 2:length(sqn)
            dn.(sqn(j-1:j)) = dn.(sqn(j-1:j)) + 1;
        end
        for j=1:length(dnn)
            feats(i,j+7) = dn.(dnn{j});
        end

    end

    % C+G
    feats(:,6) = feats(:,3) + feats(:,4);
    % A+U
    feats(:,7) = feats(:,2) + feats(:,5);

end