function ncores = init_parallel(Nworkers)
% INIT_PARALLEL initialize parallel computing,
% returning the number of system cores or [] if not found
    if nargin < 1 || isempty(Nworkers), Nworkers = 12; end
    
    ncores = [];
    vrsion = version('-release');
    
    if length(vrsion) == 0
        % we're running octave            
        try
            if isempty(ver('parallel')),pkg load parallel, end
            ncores = nproc;
        catch e
            fprintf('# could''nt load parallel package: %s\n', e.message);
        end
    
    elseif vrsion < 'R2013'
        % Matlab up to R2012b
        try, Nworkers = feature('numCores'); catch e; end
        if matlabpool('size') == 0
            while( Nworkers > 1 )
                try
                    matlabpool(Nworkers);
                    ncores = Nworkers;
                    break
                catch e
                    Nworkers = Nworkers-1;
                    fprintf('# trying %d matlabpool workers\n', Nworkers);
                end
            end
        end
    
    else
        % newer Matlab versions, just create the pool with default params
        try, ncores = feature('numCores'); catch e; end
        try, gcp; catch e
            fprintf('# couldn''t initialize parallel pool: %s\n', e.message);
        end
    end
end
