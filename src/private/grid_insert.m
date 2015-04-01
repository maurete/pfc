function grid = grid_insert(grid, param1, param2, zinterp, zignore)

    if nargin < 5, zignore = []; end
    if nargin < 4, zinterp = []; end

    % set param order to match those of the grid
    if findorder(param1) == -findorder(grid.param1)
        param1 = param1(end:-1:1);
    end
    if findorder(param2) == -findorder(grid.param2)
        param2 = param2(end:-1:1);
    end

    [newparam1 newrows reqrows] = insert(grid.param1, param1);
    [newparam2 newcols reqcols] = insert(grid.param2, param2);

    newdata = zeros(length(newparam1), ...
                    length(newparam2), ...
                    size(grid.data,3));

    for z=1:size(grid.data,3)
        newdata(~newrows,~newcols,z) = grid.data(:,:,z);

        if find(zinterp==z)
            newdata(:,:,z) = interpolate( grid.param1, grid.param2, ...
                                          grid.data(:,:,z), ...
                                          newparam1, newparam2);
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
