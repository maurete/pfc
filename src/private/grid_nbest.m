function grid = grid_nbest (grid, N, r, idx, zinterp, zignore)
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
    if nargin < 6, zignore = 1; end
    if nargin < 5, zinterp = 1; end
    if nargin < 4, idx     = 1; end
    if nargin < 3, r       = 2; end
    if nargin < 2, N       = 0.1; end

    if N < 1, N = round( N * numel(grid.data(:,:,1)) ), end

    sgn = sign(idx);
    idx = abs(idx);

    [~,indx] = sort( sgn*reshape(grid.data(:,:,idx),1,[]), 'descend' );

    ii = [];
    jj = [];
    for i=indx(1:N)
        [ix jx] = ind2sub(size(grid.data(:,:,idx)),i);
        ii = [ii;ix];
        jj = [jj;jx];
    end

    p1 = zeros(length(ii),length(-1:1/r:1));
    p2 = zeros(length(ii),length(-1:1/r:1));

    for n=1:length(ii)
        fprintf( '> best paramset \t%f\t%f\tres\t%f\n', grid.param1(ii(n)), ...
                 grid.param2(jj(n)), grid.data(ii(n), jj(n),idx))
        p1(n,:) = interp(grid.param1, [-1:1/r:1]+ii(n));
        p2(n,:) = interp(grid.param2, [-1:1/r:1]+jj(n));
    end

    for n=1:length(ii)
        if length(grid.param2) > 1
            grid = grid_insert(grid, p1(n,:), p2(n,:), zinterp, zignore);
        else
            grid = grid_insert(grid, p1(n,:), [], zinterp, zignore);
        end
    end
end
