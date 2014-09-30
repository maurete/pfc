function [ii jj] = gridzoom( grid )

if length(size(grid)) > 2, grid = grid(:,:,1); end

h = size(grid,1);
w = size(grid,2);

hsub = ceil(h/2);
wsub = ceil(w/2);

ii=0;
jj=0;
gmax = -Inf;

for i=1:h-hsub
    for j=1:w-wsub
        gsum = sum(sum(grid(i:i+hsub,j:j+wsub)));
        if gsum > gmax
            ii = [i:i+hsub]';
            jj = [j:j+wsub];
            gmax = gsum;
        end
    end
end