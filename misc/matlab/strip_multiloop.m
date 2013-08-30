function [ out ]  = strip_multiloop ( data )
    
    % formato de un string de estructura *con más de un loop*
    mult_fmt = '[.(]+\)[.()]*\([.)]+';
    
    input = {};
    
    if isstruct(data)
        input = {data.Fold};
    else
        input = data;
    end
    
    multiloop = zeros(length(input), 1);

    
    for i = 1:length(input)
        if regexp(input{i},mult_fmt)
            multiloop(i) = 1;
        end
    end
    
    out = [];
    
    if isstruct(data)
        out = struct('Header', [], 'Sequence', [], 'Fold', []);
        c = 1;
        for i = 1:length(input)
            if ~ multiloop(i)
                out(c) = data(i);
                c = c + 1;
            end
        end
    else
        out = multiloop;
    end
    
end
