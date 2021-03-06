function grid = grid_threshold (grid, thr, limit, idx, zinterp, zignore)
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
    if nargin < 6, zignore = 3; end
    if nargin < 5, zinterp = 1; end
    if nargin < 4, idx     = 1; end
    if nargin < 3, limit   = 200; end

    sgn = sign(idx);
    idx = abs(idx);

    if nargin < 2, thr = sgn * 0.9 * max(sgn*grid.data(:,:,idx)); end

    % interpolate grid
    grid = grid_insert(grid, ...
                       interp(grid.param1), ...
                       interp(grid.param2), ...
                       [zinterp idx], zignore);

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
    grid.data(:,:,zignore) = grid.data(:,:,zignore) | mask;
end
