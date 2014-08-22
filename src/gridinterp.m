function [out interp] = gridinterp( m )

    %%% gridinterp ( m ) 
    % interpolates matrix m in dimensions X,Y for every Z
    
    X = size(m,1);
    Y = size(m,2);
    Z = size(m,3);
    
    out = zeros(2*X-1, 2*Y-1, Z);
    
    % fill odd x,y values with original
    out(2*[1:X]-1,2*[1:Y]-1,:) = m(:,:,:);

    % fill intermediate points
    % top
    out(2*[1:X-1],2*[1:Y]-1,:) = 0.5*m(2:X,1:Y,:);
    % bottom
    out(2*[2:X]-2,2*[1:Y]-1,:) = out(2*[2:X]-2,2*[1:Y]-1,:) + 0.5*m(1:X-1,1:Y,:);
    % left
    out(2*[1:X]-1,2*[1:Y-1],:) = out(2*[1:X]-1,2*[1:Y-1],:) + 0.5*m(1:X,2:Y,:);
    % right
    out(2*[1:X]-1,2*[2:Y]-2,:) = out(2*[1:X]-1,2*[2:Y]-2,:) + 0.5*m(1:X,1:Y-1,:);
    % top-left
    out(2*[1:X-1],2*[1:Y-1],:) = out(2*[1:X-1],2*[1:Y-1],:) + 0.25*m(2:X,2:Y,:);
    % bottom-left
    out(2*[2:X]-2,2*[1:Y-1],:) = out(2*[2:X]-2,2*[1:Y-1],:) + 0.25*m(1:X-1,2:Y,:);
    % top-right
    out(2*[1:X-1],2*[2:Y]-2,:) = out(2*[1:X-1],2*[2:Y]-2,:) + 0.25*m(2:X,1:Y-1,:);
    % bottom-right
    out(2*[2:X]-2,2*[2:Y]-2,:) = out(2*[2:X]-2,2*[2:Y]-2,:) + 0.25*m(1:X-1,1:Y-1,:);

    % highlight interpolated values
    interp = ones(2*X-1, 2*Y-1);
    interp(2*[1:X]-1,2*[1:Y]-1) = 0;
    
end