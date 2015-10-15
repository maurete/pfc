function out = gridutil

    out.new = @new;
    function grid = new(param1, param2, n, names, varargin)
        grid = struct();
        if nargin < 3 || isempty(n), n=3; end
        if nargin > 3 && iscell(names),
            grid.names = names;
            n = length(names);
        end
        grid.param1 = reshape(param1,[],1);
        grid.param2 = reshape(param2,1,[]);
        grid.data = zeros( length(param1), length(param2), n);
    end

    out.pack = @pack;
    function [m,names] = pack(grid)
        m = zeros(prod( [size(grid.data,1), size(grid.data,2)]), size(grid.data,3)+2 );
        m(:,1) = reshape( diag(grid.param1)*ones(size(grid.data(:,:,1))), [], 1);
        m(:,2) = reshape( ones(size(grid.data(:,:,1)))*diag(grid.param2), [], 1);
        for i=1:size(grid.data,3)
            m(:,i+2) = reshape(grid.data(:,:,i), [], 1);
        end
        names = {};
        if isfield(grid,'names'), names = grid.names; end
    end

    out.unpack = @unpack;
    function grid = unpack(m,names,varargin)
        grid = struct();
        grid.param1 = unique(m(:,1),'stable');
        grid.param2 = unique(m(:,2),'stable')';
        grid.data = zeros( length(grid.param1), length(grid.param2), size(m,2)-2 );
        for i=3:size(m,2)
            grid.data(:,:,i-2) = reshape(m(:,i), length(grid.param1), length(grid.param2));
        end
        if nargin > 1 && iscell(names), grid.names = names; end
    end

    function [sign literal] = vfindorder(v)
        sign = 1;
        literal = 'ascend';
        if length(v) > 1 && v(2)-v(1) < 0
            sign = -1;
            literal = 'descend';
        end
    end

    function [v ins req] = vinsert(vec, values)

        [n s] = vfindorder(vec);

        if isrow(vec),
            values = reshape(values,1,[]);
            v = sort(unique([vec values]),s);
        else
            values = reshape(values,[],1);
            v = sort(unique([vec;values]),s);
        end

        % ins flags new elements inserted into v
        ins = logical(ones(size(v)));
        for i=1:length(vec)
            ins(find(v==vec(i))) = false;
        end
        % req flags <values> positions in v
        req = logical(zeros(size(v)));
        for i=1:length(values)
            req(find(v==values(i))) = true;
        end
    end

    % out.coords = @coords;
    % function idx = coords( xc, yc, z, xi, yi )
    %     rows = zeros(size(z));
    %     cols = zeros(size(z));
    %     for i = xi
    %         rows(find(xc == i), :, :) = 1;
    %     end
    %     for j = yi
    %         cols(:, find(yc == j), :) = 1;
    %     end
    %     idx = find(rows & cols);
    % end

    out.interpolate = @interpolate;
    function out = interpolate(xc, yc, values, xi, yi, map, varargin)
        % map is a domain-mapping function handle for working with
        % e.g. logarithmic scale. by default it is the identity mapping
        if nargin < 6, map = @(x) x; end
        xc = reshape(xc,[],1);
        xi = reshape(xi,[],1);
        yc = reshape(yc,1,[]);
        yi = reshape(yi,1,[]);

        [xo xs] = vfindorder(map(xi));
        [yo ys] = vfindorder(map(yi));
        if vfindorder(map(xc)) ~= xo, xc = xc(end:-1:1); values = values(end:-1:1,:,:); end
        if vfindorder(map(yc)) ~= yo, yc = yc(end:-1:1); values = values(:,end:-1:1,:); end

        out = zeros(length(xi),length(yi),size(values,3));

        % check for singleton dimensions of original grid
        if length(xc) < 2
            % should interpolate in y-dimension only
            for k = 1:size(values,3)
                if all(size(xi) == size(xc)) && all(xi == xc)
                    % interpolate y dimension because x has not changed
                    out(:,:,k) = interp1(map(yc),values(:,:,k),map(yi),'linear','extrap');
                else
                    % our x is now different, return NaNs
                    out(:,:,k) = nan(length(xi),length(yi));
                end
            end
            return
        end
        if length(yc) < 2
            % should interpolate in x-dimension only
            for k = 1:size(values,3)
                if all(size(yi) == size(yc)) && all(yi == yc)
                    % interpolate x dimension because y has not changed
                    out(:,:,k) = interp1(map(xc),values(:,:,k),map(xi),'linear','extrap');
                else
                    % our y-coordinate is different than original, return NaNs
                    out(:,:,k) = nan(length(xi),length(yi));
                end
            end
            return
        end

        % if here we can be sure interpolation can be performed in 2D
        aux = zeros(length(xc),length(yi),size(values,3));
        for k = 1:size(values,3)
            for i = 1:length(xc)
                aux(i,:,k) = interp1(map(yc),values(i,:,k),map(yi),'linear','extrap');
            end
            for j = 1:length(yi)
                out(:,j,k) = interp1(map(xc),aux(:,j,k),map(xi),'linear','extrap');
            end
        end
    end

    out.mapinterpolate = @mapinterpolate;
    function out = mapinterpolate(xc, yc, values, xi, yi, fwmap, bwmap)
        % map is a domain-mapping function handle for working with
        % e.g. logarithmic scale. by default it is the identity mapping
        xc = reshape(xc,[],1);
        xi = reshape(xi,[],1);
        yc = reshape(yc,1,[]);
        yi = reshape(yi,1,[]);

        [xo xs] = vfindorder(xi);
        [yo ys] = vfindorder(yi);
        if vfindorder(xc) ~= xo, xc = xc(end:-1:1); values = values(end:-1:1,:,:); end
        if vfindorder(yc) ~= yo, yc = yc(end:-1:1); values = values(:,end:-1:1,:); end

        out = zeros(length(xi),length(yi),size(values,3));

        % check for singleton dimensions of original grid
        if length(xc) < 2
            % should interpolate in y-dimension only
            for k = 1:size(values,3)
                if all(size(xi) == size(xc)) && all(xi == xc) && length(yc) > 1
                    % interpolate y dimension because x has not changed
                    out(:,:,k) = bwmap(interp1(yc,fwmap(values(:,:,k)),yi,'linear','extrap'));
                else
                    % our x is now different, return NaNs
                    out(:,:,k) = nan(length(xi),length(yi));
                end
            end
            return
        end
        if length(yc) < 2
            % should interpolate in x-dimension only
            for k = 1:size(values,3)
                if all(size(yi) == size(yc)) && all(yi == yc) && length(xc) > 1
                    % interpolate x dimension because y has not changed
                    out(:,:,k) = bwmap(interp1(xc,fwmap(values(:,:,k)),xi,'linear','extrap'));
                else
                    % our y-coordinate is different than original, return NaNs
                    out(:,:,k) = nan(length(xi),length(yi));
                end
            end
            return
        end

        % if here we can be sure interpolation can be performed in 2D
        aux = zeros(length(xc),length(yi),size(values,3));
        for k = 1:size(values,3)
            for i = 1:length(xc)
                aux(i,:,k) = bwmap(interp1(yc,fwmap(values(i,:,k)),yi,'linear','extrap'));
            end
            for j = 1:length(yi)
                out(:,j,k) = bwmap(interp1(xc,fwmap(aux(:,j,k)),xi,'linear','extrap'));
            end
        end
    end

    out.mapinterp = @mapinterp;
    function out = mapinterp( varargin )
        fwmap = @(x) x;
        bwmap = @(x) x;
        if isa(varargin{1}, 'function_handle')
            fwmap = varargin{1};
            bwmap = varargin{2};
            b = 2; e = 0;
        elseif isa(varargin{end}, 'function_handle')
            fwmap = varargin{end-1};
            bwmap = varargin{end};
            b = 0; e = 2;
        end

        if nargin == 1+b+e
            z = varargin{b+1};
            % if oly one argument given, just interpolate halfway
            % between existing points.
            if numel(z) < 2, out = z; return, end
            out = mapinterpolate( 1:size(z,1), 1:size(z,2), z, ...
                                  1:0.5:size(z,1), 1:0.5:size(z,2), ...
                                  fwmap, bwmap );
            return;

        elseif nargin == 2+b+e
            % if two arguments given, data is understood to be
            % one-dimensional and interpolated according to 2nd
            % parameter
            z  = varargin{b+1};
            xi = varargin{b+2};
            if size(z,1) == 1
                out = mapinterpolate( 1, 1:size(z,2), z, 1, xi, ...
                                      fwmap, bwmap );
                return
            elseif size(z,2) == 1
                out = mapinterpolate( 1:size(z,1), 1, z, xi, 1, ...
                                      fwmap, bwmap );
                return
            end

        elseif nargin == 3+b+e
            % if three arguments given, data is understood to be
            % one-dimensional and interpolated according to 3rd
            % parameter
            xc = varargin{b+1};
            z  = varargin{b+2};
            xi = varargin{b+3};
            if size(z,1) == 1
                out = mapinterpolate( 1, xc, z, 1, xi, fwmap, bwmap );
                return
            elseif size(z,2) == 1
                out = mapinterpolate( xc, 1, z, xi, 1, fwmap, bwmap );
                return
            end

        elseif nargin == 5+b+e
            % if five arguments given, data is understood to be
            % two-dimensional and interpolated according to 4th
            % and 5th parameter
            out = mapinterpolate(varargin{b+1}, varargin{b+2}, varargin{b+3}, ...
                                 varargin{b+4}, varargin{b+5}, fwmap, bwmap );
            return
        end
        throw(MException('Invalid function call'))
    end

    out.interp = @interp;
    function out = interp( varargin )

        map = @(x) x; b = 0; e = 0;
        if isa(varargin{1}, 'function_handle')
            map = varargin{1}; b = 1; e = 0;
        elseif isa(varargin{end}, 'function_handle')
            map = varargin{end}; b = 0; e = 1;
        end

        if nargin == 1+b+e
            z = varargin{b+1};
            % if oly one argument given, just interpolate halfway
            % between existing points.
            out = interpolate( 1:size(z,1), 1:size(z,2), z, ...
                               1:0.5:size(z,1), 1:0.5:size(z,2), map );
            return;

        elseif nargin == 2+b+e
            % if two arguments given, data is understood to be
            % one-dimensional and interpolated according to 2nd
            % parameter
            z  = varargin{b+1};
            xi = varargin{b+2};
            if size(z,1) == 1
                out = interpolate( 1, 1:size(z,2), z, 1, xi, map );
                return
            elseif size(z,2) == 1
                out = interpolate( 1:size(z,1), 1, z, xi, 1, map );
                return
            end

        elseif nargin == 3+b+e
            % if three arguments given, data is understood to be
            % one-dimensional and interpolated according to 3rd
            % parameter
            xc = varargin{b+1};
            z  = varargin{b+2};
            xi = varargin{b+3};
            if size(z,1) == 1
                out = interpolate( 1, xc, z, 1, xi, map );
                return
            elseif size(z,2) == 1
                out = interpolate( xc, 1, z, xi, 1, map );
                return
            end

        elseif nargin == 5+b+e
            % if five arguments given, data is understood to be
            % two-dimensional and interpolated according to 4th
            % and 5th parameter
            out = interpolate(varargin{b+1}, varargin{b+2}, varargin{b+3}, ...
                              varargin{b+4}, varargin{b+5}, map );
            return
        end
        throw(MException('Invalid function call'))
    end

    out.insert = @insert;
    function grid = insert(grid, param1, param2, zinterp, zignore, map)

        if nargin < 6, map = @(x) x; end
        if nargin < 5, zignore = []; end
        if nargin < 4, zinterp = []; end

        % set param order to match those of the grid
        if vfindorder(param1) ~= vfindorder(grid.param1)
            param1 = param1(end:-1:1);
        end
        if vfindorder(param2) ~= vfindorder(grid.param2)
            param2 = param2(end:-1:1);
        end

        [newparam1 newrows reqrows] = vinsert(grid.param1, param1);
        [newparam2 newcols reqcols] = vinsert(grid.param2, param2);

        newdata = zeros(length(newparam1), ...
                        length(newparam2), ...
                        size(grid.data,3));

        for z=1:size(grid.data,3)
            newdata(~newrows,~newcols,z) = grid.data(:,:,z);

            if find(zinterp==z)
                newdata(:,:,z) = interp( grid.param1, grid.param2, ...
                                         grid.data(:,:,z), ...
                                         newparam1, newparam2, map );
            elseif find(zignore==z)
                newdata(newrows,:,z) = 1;
                newdata(:,newcols,z) = 1;
                newdata(reqrows,reqcols,z) = 0;
            end
        end

        grid.data   = newdata;
        grid.param1 = newparam1;
        grid.param2 = newparam2;

    end

    out.plot = @plotgrid;
    function ax = plotgrid( varargin )

        idx = []; grid = {}; gc = 0;
        map = @(x) x;

        for i = 1:nargin
            if isa(varargin{i},'struct')
                gc = gc+1;
                grid{gc} = varargin{i};
            elseif isa(varargin{i},'function_handle')
                map = varargin{i};
            else
                idx = varargin{i};
            end
        end

        if numel(grid{1}.param2) < 2
            figure
            hold all
            h = [];
            l = {};
            for g = 1:gc
                for i=1:length(idx)
                    h = [h plot(log2(grid{g}.param1), map(grid{g}.data(:,:,idx(i))))];
                    if isfield(grid{g},'names')
                        l{g+i-1} = ['grid ' num2str(g) ' ' grid{g}.names{idx(i)} ];
                    else
                        l{g+i-1} = ['grid ' num2str(g) ' idx ' num2str(idx(i)) ];
                    end
                end
            end
            legend(h,l)
            xlabel( 'log2(C)' )
            hold off
        else
            % more complex surface plot
            figure
            hold all
            h = [];
            l = {};
            for g = 1:gc
                for i=1:length(idx)
                    h = [h mesh(log2(grid{g}.param2),log2(grid{g}.param1), map(grid{g}.data(:,:,idx(i))))];
                    if isfield(grid{g},'names')
                        l{g+i-1} = ['grid ' num2str(g) ' ' grid{g}.names{idx(i)} ];
                    else
                        l{g+i-1} = ['grid ' num2str(g) ' idx ' num2str(idx(i)) ];
                    end
                end
            end
            legend(h,l)
            ylabel( 'log2(C)' )
            xlabel('log2(\gamma)')
            hold off
        end
    end

    out.color = @colorgrid;
    function ax = colorgrid( grid, idx, map )
        if nargin < 3, map = @(x) x; end
        % color plot
        figure
        ax = pcolor(log2(grid.param2),log2(grid.param1), map(grid.data(:,:,idx(1))));
        ylabel( 'log2(C)' )
        xlabel('log2(\gamma)')
        shading flat
        %colormap winter
    end

end
