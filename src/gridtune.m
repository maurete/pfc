function out = gridtune
%GRIDTUNE
%
    gu = gridutil;

    out.zoom = @zoom;
    function grid = zoom (grid, X, idx, interp, ignore, dmap, fmap)
    % zoom - 'Zoom' into grid's best performing region. Output grid
    % is interpolated within this region with resolution 1/X.
    %
    % @param   grid: grid to operate on
    % @param      X: zoom factor, by default 2
    % @param    idx: Z-index of the data matrix where to search
    % @param interp: Z-index(es) of the data matrix to be interpolated
    % @param ignore: Z-index(es) where to mark elements as 'ignored'
    %                outside region of interest
        if nargin < 7, fmap = @(x) x; end
        if nargin < 6, dmap = @(x) x; end
        if nargin < 5, interp = 1; end
        if nargin < 4, idx    = 1; end
        if nargin < 3, X      = 2; end

        sgn = sign(idx);
        idx = abs(idx);

        % height and width of 'zoom window'
        wh = ceil(size(grid.data,1)/X);
        ww = ceil(size(grid.data,2)/X);

        % convolve with constant-1 window and find best region
        res = conv2(grid.data(:,:,idx), ones([wh ww]), 'valid');
        [ii jj] = find(sgn*res==max(sgn*res(:)),1,'first');

        % interpolate parameters inside best region
        new1 = gu.mapinterp( 1:wh, grid.param1([1:wh]+ii-1), 1:1/X:wh, fmap, dmap);
        new2 = [];
        if ww>1, new2 = gu.mapinterp( 1:ww, grid.param2([1:ww]+jj-1), 1:1/X:ww, fmap, dmap);
        end

        % insert new parameters into grid
        grid = gu.insert(grid,new1,new2,interp,ignore,fmap);
    end

    out.threshold = @threshold;
    function grid = threshold (grid, thr, limit, idx, interp, ignore, dmap, fmap)
    % threshold - Interpolate results grid and then values which fall
    % below threshold as 'ignored'. Cap maximum number of elements to
    % <limit>.
    %
    % @param   grid: grid to operate on
    % @param    thr: threshold value, by default 0.9 (90%)
    % @param  limit: maximum number of un-ignored elements
    % @param    idx: Z-index of the data matrix where to search
    % @param interp: Z-index(es) of the data matrix to be interpolated
    % @param ignore: Z-index(es) where to mark elements as 'ignored'
    %                outside region of interest
        if nargin < 8, fmap = @(x) x; end
        if nargin < 7, dmap = @(x) x; end
        if nargin < 6, ignore = 3; end
        if nargin < 5, interp = 1; end
        if nargin < 4, idx    = 1; end
        if nargin < 3, limit  = 200; end

        sgn = sign(idx);
        idx = abs(idx);

        if nargin < 2, thr = sgn * 0.9 * max(sgn*grid.data(:,:,idx)); end

        % interpolate grid
        grid = gu.insert(grid, ...
                         gu.mapinterp(grid.param1, fmap, dmap), ...
                         gu.mapinterp(grid.param2, fmap, dmap), ...
                         [interp idx], ignore, fmap);

        % mask (ignore) values below threshold
        mask = zeros( length(grid.param1), length(grid.param2));
        mask( find( sgn*grid.data(:,:,idx) < sgn*thr) ) == 1;

        % keep only <limit> best elements
        if sum(sum(1-mask)) > limit
            [~,idx]  = sort( sgn*reshape(grid.data(:,:,idx),1,[]) );
            %mask(idx(1:max(round(thr*numel(mask)),numel(mask)-limit))) = 1;
            mask(idx(1:(numel(mask)-limit))) = 1;
        end

        % apply mask to grid's 'ignore' index
        grid.data(:,:,ignore) = grid.data(:,:,ignore) | mask;
    end

    out.nbest = @nbest;
    function grid = nbest (grid, N, r, idx, interp, ignore, dmap, fmap)
    % nbest - Find N best results and then interpolate around those
    % elements with resolution r
    %
    % @param   grid: grid to operate on
    % @param      N: (N>=1) number of elements or (N<1) proportion
    %                over total number of elements to detail
    % @param      r: resolution of interpolation around best elements
    % @param    idx: Z-index of the data matrix where to search
    % @param interp: Z-index(es) of the data matrix to be interpolated
    % @param ignore: Z-index(es) where to mark elements as 'ignored'
    %                outside region of interest
        if nargin < 8, fmap = @(x) x; end
        if nargin < 7, dmap = @(x) x; end
        if nargin < 6, ignore = 1; end
        if nargin < 5, interp = 1; end
        if nargin < 4, idx    = 1; end
        if nargin < 3, r      = 2; end
        if nargin < 2, N      = 0.1; end

        if N < 1, N = round( N * numel(grid.data(:,:,1)) ), end

        sgn = sign(idx);
        idx = abs(idx);

        [~,indx] = sort( sgn*reshape(grid.data(:,:,idx),1,[]) );

        ii = [];
        jj = [];
        for i=unique(zz(1:N))
            [ix jx] = ind2sub(size(grid.data(:,:,idx)), find([grid.data(:,:,idx)==i]));
            ii = [ii;ix];
            jj = [jj;jx];
        end

        p1 = zeros(length(ii),length(-1:1/r:1));
        p2 = zeros(length(ii),length(-1:1/r:1));

        for n=1:length(ii)
            fprintf( '> best paramset (map) \t%f\t%f\tres\t%f\n', fmap(grid.param1(ii(n))), ...
                     fmap(grid.param2(jj(n))), grid.data(ii(n), jj(n),idx))
            p1(n,:) = gu.mapinterp(grid.param1, [-1:1/r:1]+ii(n), fmap, dmap);
            p2(n,:) = gu.mapinterp(grid.param2, [-1:1/r:1]+jj(n), fmap, dmap);
        end

        % TODO should not need to do this
        p1(p1<0) = min(min(abs(p1)));
        p2(p2<0) = min(min(abs(p2)));

        for n=1:length(ii)
            if length(grid.param2) > 1
                grid = gu.insert(grid, p1(n,:), p2(n,:), interp, ignore, fmap);
            else
                grid = gu.insert(grid, p1(n,:), [], interp, ignore, fmap);
            end
        end
    end

end
