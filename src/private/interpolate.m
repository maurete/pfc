function out = interpolate(xc, yc, values, xi, yi)
% interpolate <values> in 1st and 2nd dimension along
% every 3rd-dimension

    xc = reshape(xc,[],1);
    xi = reshape(xi,[],1);
    yc = reshape(yc,1,[]);
    yi = reshape(yi,1,[]);

    if findorder(xc) ~= findorder(xi)
        xc = xc(end:-1:1);
        values = values(end:-1:1,:,:);
    end
    if findorder(yc) ~= findorder(yi),
        yc = yc(end:-1:1);
        values = values(:,end:-1:1,:);
    end

    out = zeros(length(xi),length(yi),size(values,3));

    % check for singleton dimensions of original grid
    if length(xc) < 2
        % should interpolate in y-dimension only
        for k = 1:size(values,3)
            if all(size(xi) == size(xc)) && all(xi == xc) && length(yc) > 1
                % interpolate y dimension because x has not changed
                out(:,:,k) = interp1(yc,values(:,:,k),yi,'linear','extrap');
            else
                % our x is now different, or len(yc) < 2, return NaNs
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
                out(:,:,k) = interp1(xc,values(:,:,k),xi,'linear','extrap');
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
            aux(i,:,k) = interp1(yc,values(i,:,k),yi,'linear','extrap');
        end
        for j = 1:length(yi)
            out(:,j,k) = interp1(xc,aux(:,j,k),xi,'linear','extrap');
        end
    end
end
