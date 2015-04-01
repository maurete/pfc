function [lg] = grid_linearize(grid)
% return linearized grid for easy indexing

    [P2,P1] = meshgrid(grid.param2, grid.param1);
    [I2,I1] = meshgrid(1:length(grid.param2),1:length(grid.param1));

    lg.size = size(grid.data(:,:,1));
    lg.params = [reshape(P1,[],1) reshape(P2,[],1)];
    lg.indx = [reshape(I1,[],1) reshape(I2,[],1)];

    lg.data = reshape(grid.data,[],size(grid.data,3),1);
    lg.name = grid.name;

end

