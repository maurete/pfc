function out = interp( varargin )

    if nargin == 1
        % if only one argument given, just interpolate halfway
        % between existing points.
        z = varargin{1};
        out = interpolate( 1:size(z,1), 1:size(z,2), z, ...
                           1:0.5:size(z,1), 1:0.5:size(z,2) );
        return;

    elseif nargin == 2
        % if two arguments given, data is understood to be
        % one-dimensional and interpolated according to 2nd
        % parameter
        z  = varargin{1};
        xi = varargin{2};
        if size(z,1) == 1
            out = interpolate( 1, 1:size(z,2), z, 1, xi );
            return
        elseif size(z,2) == 1
            out = interpolate( 1:size(z,1), 1, z, xi, 1 );
            return
        end

    elseif nargin == 3
        % if three arguments given, data is understood to be
        % one-dimensional and interpolated according to 3rd
        % parameter
        xc = varargin{1};
        z  = varargin{2};
        xi = varargin{3};
        if size(z,1) == 1
            out = interpolate( 1, xc, z, 1, xi );
            return
        elseif size(z,2) == 1
            out = interpolate( xc, 1, z, xi, 1 );
            return
        end

    elseif nargin == 5
        % if five arguments given, data is understood to be
        % two-dimensional and interpolated according to 4th
        % and 5th parameter
        out = interpolate(varargin{1}, varargin{2}, varargin{3}, ...
                          varargin{4}, varargin{5} );
        return
    end

    throw(MException('Invalid function call'))
end
