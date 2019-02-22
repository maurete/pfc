function out = featset_index(i)
    % featureset indexes
    fi = { 1:66; ...          % 1 all features
           1:32; ...          % 2 triplet
           33:36; ...         % 3 triplet-extra
           37:59; ...         % 4 sequence
           60:66; ...         % 5 secondary srtucture
           1:36; ...          % 6 triplet + extra
           [1:36, 60:66]; ...  % 7 triplet + extra + secondary structure
           37:66; ...         % 8 sequence + secondary structure
           1:59; ...          % 9 triplet + extra + sequence
           33:66; ...         % 10 triplet-extra + sequence + secondary struct
           [33:36, 60:66]; ... % 11 triplet-extra + secondary structure
           33:59; ...         % 12 triplet-extra + sequence
           [1:32, 60:66]; ...  % 13 triplet + struct
           [1:32, 37:59]; ...  % 14 tiplet + sequence
           [1:32, 37:66]; ...  % 15 tiplet + sequence + struct
           [35,60]; ...       % toy feature set for tests
         };
    out = fi{i};
end
