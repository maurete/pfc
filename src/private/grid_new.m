function grid = grid_new(param1, param2, layer)
    grid = struct();
    if nargin < 3 || isempty(layer)
        grid.name = { 'test'    , ... % tested flag
                      'ign'     , ... % ignore flag
                      'er'      , ... % error rate
                      'pr'      , ... % precision
                      'se'      , ... % sensitivity (recall)
                      'sp'      , ... % specificity
                      'gm'      , ... % geomean(se,sp)
                      'fm'      , ... % F-measure
                      'mc'      , ... % Matthews Correlation Coefficient
                      'emp'     , ... % empirical error (Adankon et al.)
                      'rmb'       ... % RMB (Chung et al.)
                    };
        n = length(grid.name);
    elseif isnumber(layer)
        n = layer;
    end
    grid.param1 = reshape(param1,[],1);
    grid.param2 = reshape(param2,1,[]);
    grid.data = zeros( length(param1), length(param2), n);
end
