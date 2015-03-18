function grid = grid_zoom (grid, X, idx, interp, ignore, dmap, fmap)
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
    new1 = grid_mapinterp( 1:wh, grid.param1([1:wh]+ii-1), 1:1/X:wh, fmap, dmap);
    new2 = [];
    if ww>1, new2 = grid_mapinterp( 1:ww, grid.param2([1:ww]+jj-1), 1:1/X:ww, fmap, dmap);
    end

    % insert new parameters into grid
    grid = grid_insert(grid,new1,new2,interp,ignore,fmap);
end