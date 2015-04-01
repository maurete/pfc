function init_matlabpool(Nworkers)

    % initialize matlabpool
    if nargin < 1 || isempty(Nworkers), Nworkers = 12; end
    try
        if matlabpool('size') == 0
            while( Nworkers > 1 )
                try
                    matlabpool(Nworkers);
                    break
                catch e
                    Nworkers = Nworkers-1;
                    fprintf('# trying %d workers\n', Nworkers);
                end
            end
        end
    catch e
    end
    % fprintf('# using %d matlabpool workers\n', matlabpool('size'));
end