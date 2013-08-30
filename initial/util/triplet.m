function out = triplet ( sequence, structure, normalize )

    assert(length(sequence) == length(structure), '%d != %d', length(sequence) ,length(structure))
    
    aux = strfind(structure, '(');
    ll = aux(1);
    lr = aux(end);
    aux = strfind(structure, ')');
    rl = aux(1);
    rr = aux(end);
    
    % ignoro primer y ultimo caracter de la secuencia
    ll = max(ll,2);
    rr = min(rr,length(sequence)-1);
    
    assert(lr < rl)
    
    % convierto . y ( a 0 y 1 (
    structure = strrep(structure, '.', '0');
    structure = strrep(structure, '(', '1');
    structure = strrep(structure, ')', '1');

    sequence = strrep(sequence, 'G', '0');
    sequence = strrep(sequence, 'C', '1');
    sequence = strrep(sequence, 'U', '2');
    sequence = strrep(sequence, 'A', '3');
    
    out = zeros (1,32);
    sum = 0;
    
    for i=[ll:lr rl:rr]
        % valor nt * 8 + valor struct (bin) + 1
        idx = 8 * str2num(sequence(i)) + bin2dec(structure(i-1:i+1)) ...
              + 1;
        out(idx) = out(idx) + 1;
        sum = sum + 1;
    end
    
    if nargin < 3
        normalize = 1;
    end
    
    if normalize
        out = out ./ sum;
    end
       
end