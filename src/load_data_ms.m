function [ tr ] = load_data_ms ( id, seed, symmetric )

    if nargin < 3, symmetric = false; end
    if nargin < 2, seed = 0; end

    com = common;

    scalefun = @scale_data;
    if symmetric, scalefun = @scale_sym; end

    stpick    = @(x,n) com.stpick(seed,x,n);
    stshuffle = @(x)   com.stshuffle(seed,x);

    tr = struct();

    % load train datasets
    if strcmpi(id,'xue')

        real1_tr   = loadset('mirbase50/3svm-train', 'human', 0); % 163 hsa
        real1_ts   = loadset('mirbase50/3svm-test',  'human', 0); % 30 hsa
        pseudo1_tr = loadset('coding/3svm-train',      'all', 3); % 168 hsa
        pseudo1_ts = loadset('coding/3svm-test',       'all', 3); % 1000 hsa

        real   = stshuffle([real1_tr;real1_ts]);     % 163 real for training
        pseudo = stshuffle([pseudo1_tr;pseudo1_ts]); % 168 pseudo

        % scale the data to the range [-1:1]
        [real(:,1:66) f s] = scalefun(real(:,1:66));
        [pseudo(:,1:66)]   = scalefun(pseudo(:,1:66),f,s);

        tr.real   = real;
        tr.pseudo = pseudo;

        tr.scale_f = f;
        tr.scale_s = s;

        % * no test datasets * -- this function should be called only to load whole training set

    elseif strcmpi(id,'ng')

        real1   = loadset('mirbase82-mipred', 'human', 0);     % 308/323  hsa
        pseudo1 = loadset('coding', 'all', 2);             % 8494 hsa

        real   = stshuffle(real1);
        pseudo = stshuffle(pseudo1);

        % scale the data to the range [-1:1]
        [real(:,1:66) f s] = scalefun(real(:,1:66));
        [pseudo(:,1:66)]   = scalefun(pseudo(:,1:66),f,s);

        tr.real   = real;
        tr.pseudo = pseudo;

        tr.scale_f = f;
        tr.scale_s = s;

        % * no test datasets * -- this function should be called only to load whole training set

    elseif strcmpi(id,'ng-multi')

        real   = stshuffle(loadset('mirbase82-mipred/multi', 'human', 0));     % 323  hsa
        pseudo = stshuffle(loadset('coding', 'all', 2));                   % 8494 hsa

        % scale the data to the range [-1:1]
        [real(:,1:66) f s] = scalefun(real(:,1:66));
        [pseudo(:,1:66)]   = scalefun(pseudo(:,1:66),f,s);

        tr.real   = real;
        tr.pseudo = pseudo;

        tr.scale_f = f;
        tr.scale_s = s;

        % * no test datasets * -- this function should be called only to load whole training set

    elseif strcmpi(id,'batuwita')

        real0   = stshuffle(loadset('mirbase12-micropred', 'human', 0)); % 660/691  hsa
        pseudo1 = stshuffle(loadset('coding', 'all', 2));                % 8494 hsa
        pseudo2 = stshuffle(loadset('other-ncrna', 'all', 3));           % 129/754  hsa

        % NOTE: as there is not a train/test ratio specified on paper,
        % we set to consider 85% of real1 for training
        % and pseudo1 proportionally as well

        real   = real0;    % 561 real for training
        pseudo = stshuffle([pseudo1;pseudo2]); % 1122 pseudo

        % scale the data to the range [-1:1]
        [real(:,1:66) f s] = scalefun(real(:,1:66));
        [pseudo(:,1:66)]   = scalefun(pseudo(:,1:66),f,s);

        tr.real   = real;
        tr.pseudo = pseudo;

        tr.scale_f = f;
        tr.scale_s = s;

        % * no test datasets * -- this function should be called only to load whole training set

    elseif strcmpi(id,'batuwita-multi')

        real0   = stshuffle(loadset('mirbase12-micropred/multi', 'human', 0)); % 691  hsa
        pseudo1 = stshuffle(loadset('coding', 'all', 2));            % 8494 hsa
        pseudo2 = stshuffle(loadset('other-ncrna/multi', 'all', 3)); % 754  hsa

        % NOTE: as there is not a train/test ratio specified on paper,
        % we set to consider 85% of real1 for training
        % and pseudo1 proportionally as well

        real   = real0;    % 587 real for training
        pseudo = stshuffle([pseudo1;pseudo2]); % 1174 pseudo

        % scale the data to the range [-1:1]
        [real(:,1:66) f s] = scalefun(real(:,1:66));
        [pseudo(:,1:66)]   = scalefun(pseudo(:,1:66),f,s);

        tr.real   = real;
        tr.pseudo = pseudo;

        tr.scale_f = f;
        tr.scale_s = s;

        % * no test datasets * -- this function should be called only to load whole training set

    end
end