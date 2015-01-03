function out = gridtune
%GRIDTUNE
%

out.zoom = @zoom;
    function [values, params, test, mask] = zoom (values, params, test, mask)

    % find 'zoom region' with best rates
    [ii jj] = gridzoom(values(:,:,1));

    % interpolate sub-grids
    values = gridinterp(values(ii,jj,:));
    params = gridinterp(params(ii,jj,:));

    % restore test and mask grids
    [test aux] = gridinterp(test(ii,jj,:));
    test = [test & 1-aux]*1;
    mask = floor(gridinterp(mask(ii,jj,:)));

    end

out.threshold = @threshold;
    function [values, params, test, mask] = threshold (values, params, test, mask, thr, limit)

    if nargin < 6, limit = 200; end
    if nargin < 5, thr = 0.9; end

    % interpolate grid
    values = gridinterp(values);
    params = gridinterp(params);

    % restore test and mask grids
    [test aux] = gridinterp(test);
    test = [test & 1-aux]*1;
    mask = floor(gridinterp(mask));

    % mask values below threshold
    [zz idx]  = sort(values(1:numel(values(:,:,1))));
    % TODO the following leaves at most 200 elements unmasked.
    % should be more general.
    mask(idx(1:max(round(thr*numel(mask)),numel(mask)-limit))) = 1;

    end

out.bestneighbor = @bestneighbor;
    function [values, params, test, mask] = bestneighbor (values, params, test, mask, precision)

    if nargin < 5, precision = 0.25; end

    np = size(params,3);

    % get dx, dy for each parameter
    cur_dx = zeros(1,np);
    cur_dy = zeros(1,np);
    if size(params,1) > 1
        cur_dy = reshape(params(2,1,:)-params(1,1,:),1,[],1);
    end
    if size(params,2) > 1
        cur_dx = reshape(params(1,2,:)-params(1,1,:),1,[],1);
    end

    rw = ceil(max([cur_dx.*sign(cur_dx)]/2)/precision);
    rh = ceil(max([cur_dy.*sign(cur_dy)]/2)/precision);
    nw = 2*rw+1;
    nh = 2*rh+1;

    % find best central value
    [ii jj] = find(values(:,:,1)==max(max(values(:,:,1))),1,'first');

    cvalues = values(ii,jj,:);
    cparams = params(ii,jj,:);

    values = zeros(nh, nw, size(values,3));
    values(rh+1,rw+1,:) = cvalues;

    params = zeros(nh, nw, np);
    for i=1:np
        p = cparams(i);
        dx = cur_dx(i);
        dy = cur_dy(i);
        params(:,:,i) = ones(nh,nw)*diag(linspace(p-dx/2,p+dx/2,nw));
        if dy ~= 0
            params(:,:,i) = diag(linspace(p-dy/2,p+dy/2,nh))*ones(nh,nw);
        end
    end

    mask = zeros(nh, nw, size(mask,3));
    test = zeros(nh, nw, size(test,3));

    end

end