function [grid] = grid_repack(lg)
% rebuild grid from linearized one

    P1 = reshape(lg.params(:,1), lg.size(1), lg.size(2));
    P2 = reshape(lg.params(:,2), lg.size(1), lg.size(2));

    grid.param1 = P1(:,1);
    grid.param2 = P2(1,:);

    grid.data = reshape(lg.data,lg.size(1), lg.size(2), []);

    grid.name = lg.name;

end
