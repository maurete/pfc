function init_matlabpool(Nworkers)
    % initialize matlabpool
    if nargin < 1 || isempty(Nworkers), Nworkers = 12; end
    try
        if version('-release') < 'R2013'
            try, Nworkers = feature('numCores'); catch e; end
            if matlabpool('size') == 0
                while( Nworkers > 1 )
                    try, matlabpool(Nworkers); break
                    catch e
                        Nworkers = Nworkers-1;
                        fprintf('# trying %d matlabpool workers\n', Nworkers);
                    end
                end
            end
        else
            % in newer versions just try to create the pool with default params
            parpool
        end
    catch e
    end
end
