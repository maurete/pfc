function [ Header, Sequence, Fold ]  = fastaread ( filename )
    
    data = struct('Header', [], 'Sequence', [], 'Fold', []);

    % formato de la linea de descripcion:
    desc_fmt = '^>([\w_-]+)?(\s*(.+))?\s*$';
    % formato de la linea de secuencia:
    seqn_fmt = '^([ACGTURYKMSWBDHVNX]+)\s*$';
    % formato de la linea de estructura secundaria:
    fold_fmt_strict = '^([.()]+)(\s+\((\s*-?[0-9.]+)\s*\))?\s*$';
    fold_fmt = '^([.()]+)';
    % formato de un string de estructura *con más de un loop*
    mult_fmt = '[.(]+\)[.()]*\([.)]+';

    fid = fopen ( filename );
    lin = fgetl ( fid );
    
    count = 0;
    
    while lin ~= -1
        if regexpi(lin, desc_fmt)
            count = count + 1;
            data(count).Header = lin;
        elseif regexpi(lin, seqn_fmt)
            if count == 0
                count = 1;
            end
            data(count).Sequence = [ data(count).Sequence lin ];
        elseif regexpi(lin, fold_fmt_strict)
            [matchstart matchend] = regexpi(lin, fold_fmt);
            data(count).Fold =  [ data(count).Fold lin(matchstart:matchend) ];
        end
        lin = fgetl(fid);
    end
    
    fclose(fid);

    if nargout == 1
        Header = data;
    else
        Header = {data.Header};
        Sequence = {data.Sequence};
        Fold = {data.Fold};
    end

end



