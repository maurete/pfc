function [ tr ts ] = load_data ( id, seed, symmetric )

    scalefun = @scale_data;
    if nargin > 2 && symmetric
        scalefun = @scale_sym;
    end
    
    pick      = @(x,n) x(randsample(size(x,1),min(size(x,1),n)),:);
    shuffle   = @(x)   x(randsample(size(x,1),size(x,1)),:);
    stpick    = @(x,n) x(strandsample(seed,size(x,1),min(size(x,1),n)),:);
    stshuffle = @(x)   x(strandsample(seed,size(x,1),size(x,1)),:);

    tr = struct();
    ts = struct();
    
    % load train datasets
    if strcmpi(id,'xue')

        real1   = loadset('mirbase50', 'human', 0);         % 193  hsa
        real2   = loadset('cross-species', 'non-human', 1); % 581  other
        real3   = loadset('updated',   'all', 2);         % 39   hsa  
        pseudo1 = loadset('coding',    'all', 3);         % 8494 hsa
        pseudo2 = loadset('conserved-hairpin', 'all', 4); % 2444  hsa

        real0   = stshuffle(real1);
        pseudo0 = stshuffle(pseudo1);
        
        real   = real0(1:163,:);  % 163 real for training
        pseudo = pseudo0(1:168,:); % 168 pseudo

        % scale the data to the range [-1:1]
        [real(:,1:66) f s] = scalefun(real(:,1:66));
        [pseudo(:,1:66)]   = scalefun(pseudo(:,1:66),f,s);

        tr.real   = real;
        tr.pseudo = pseudo;
        
        tr.scale_f = f;
        tr.scale_s = s;        
    
        % test datasets (not used for CV)
        ts(1).name   = 'mirbase50-h';
        ts(1).class  = 1;
        data         = real0( 164:end,:);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(1).data   = data;

        ts(2).name   = 'mirbase50-nh';
        ts(2).class  = 1;
        data         = real2;
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(2).data   = data;
    
        ts(3).name   = 'updated-h';
        ts(3).class  = 1;
        data         = real3;
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(3).data   = data;

        ts(4).name   = 'coding-h';
        ts(4).class  = -1;
        data         = stpick(pseudo0(169:end,:),1000);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(4).data   = data;

        ts(5).name   = 'conserved-hairpin-h';
        ts(5).class  = -1;
        data         = pseudo2;
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(5).data   = data;

        ts(6).name   = 'mirbase20-h';
        ts(6).class  = 1;
        data         = loadset('mirbase20','human',6);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(6).data   = data;

        ts(7).name   = 'mirbase20-nh';
        ts(7).class  = 1;
        data         = loadset('mirbase20','non-human',7);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(7).data   = data;

        
    elseif strcmpi(id,'ng')

        real1   = loadset('mirbase82-mipred', 'human', 0);     % 308/323  hsa
        real2   = loadset('mirbase82-mipred', 'non-human', 1); % 1677/1918  other
        pseudo1 = loadset('coding', 'all', 2);             % 8494 hsa
        pseudo2 = loadset('functional-ncrna', 'all', 3);   % 2657/12387  all

        real0   = stshuffle(real1);
        pseudo0 = stshuffle(pseudo1);
        
        real   = real0(1:190,:);   % 200 real for training
        pseudo = pseudo0(1:380,:); % 400 pseudo

        % scale the data to the range [-1:1]
        [real(:,1:66) f s] = scalefun(real(:,1:66));
        [pseudo(:,1:66)]   = scalefun(pseudo(:,1:66),f,s);

        tr.real   = real;
        tr.pseudo = pseudo;
        
        tr.scale_f = f;
        tr.scale_s = s;        
    
        % test datasets (not used for CV)
        ts(1).name   = 'mirbase82-h';
        ts(1).class  = 1;
        data         = real0( 191:end,:);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(1).data   = data;

        ts(2).name   = 'mirbase82-nh';
        ts(2).class  = 1;
        data         = real2;
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(2).data   = data;
    
        ts(3).name   = 'coding-h';
        ts(3).class  = -1;
        data         = stpick(pseudo0(381:end,:),236+3354); % original = 246 + 3836
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(3).data   = data;

        ts(4).name   = 'functional-ncrna';
        ts(4).class  = -1;
        data         = pseudo2;
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(4).data   = data;

        ts(5).name   = 'mirbase20-h';
        ts(5).class  = 1;
        data         = loadset('mirbase20','human',6);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(5).data   = data;

        ts(6).name   = 'mirbase20-nh';
        ts(6).class  = 1;
        data         = loadset('mirbase20','non-human',7);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(6).data   = data;
        
    elseif strcmpi(id,'ng-multi')

        real0   = stshuffle(loadset('mirbase82-mipred/multi', 'human', 0));     % 323  hsa
        pseudo0 = stshuffle(loadset('coding', 'all', 2));                   % 8494 hsa
        
        real   = real0(1:200,:);   % 200 real for training
        pseudo = pseudo0(1:400,:); % 400 pseudo

        % scale the data to the range [-1:1]
        [real(:,1:66) f s] = scalefun(real(:,1:66));
        [pseudo(:,1:66)]   = scalefun(pseudo(:,1:66),f,s);

        tr.real   = real;
        tr.pseudo = pseudo;
        
        tr.scale_f = f;
        tr.scale_s = s;        
    
        % test datasets (not used for CV)
        ts(1).name   = 'mirbase82-h';
        ts(1).class  = 1;
        data         = real0( 201:end,:);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(1).data   = data;

        ts(2).name   = 'mirbase82-nh';
        ts(2).class  = 1;
        data         = loadset('mirbase82-mipred/multi', 'non-human', 1);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(2).data   = data;
    
        ts(3).name   = 'coding-h';
        ts(3).class  = -1;
        data         = stpick(pseudo0(401:end,:),246+3836); % original = 246 + 3836
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(3).data   = data;

        ts(4).name   = 'functional-ncrna';
        ts(4).class  = -1;
        data         = loadset('functional-ncrna/multi', 'all', 3);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(4).data   = data;

        ts(5).name   = 'mirbase20-h';
        ts(5).class  = 1;
        data         = loadset('mirbase20/multi','human',6);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(5).data   = data;

        ts(6).name   = 'mirbase20-nh';
        ts(6).class  = 1;
        data         = loadset('mirbase20/multi','non-human',7);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(6).data   = data;

    elseif strcmpi(id,'batuwita')

        real0   = stshuffle(loadset('mirbase12-micropred', 'human', 0)); % 660/691  hsa
        pseudo1 = stshuffle(loadset('coding', 'all', 2));                % 8494 hsa
        pseudo2 = stshuffle(loadset('other-ncrna', 'all', 3));           % 129/754  hsa

        % NOTE: as there is not a train/test ratio specified on paper,
        % we set to consider 85% of real1 for training
        % and pseudo1 proportionally as well
        
        real   = real0(1:561,:);    % 561 real for training
        pseudo = stshuffle([pseudo1(1:1022,:);pseudo2(1:100,:)]); % 1122 pseudo

        % scale the data to the range [-1:1]
        [real(:,1:66) f s] = scalefun(real(:,1:66));
        [pseudo(:,1:66)]   = scalefun(pseudo(:,1:66),f,s);

        tr.real   = real;
        tr.pseudo = pseudo;
        
        tr.scale_f = f;
        tr.scale_s = s;        
    
        % test datasets (not used for CV)
        ts(1).name   = 'mirbase12-h';
        ts(1).class  = 1;
        data         = real0( 562:end,:); % 99 hsa
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(1).data   = data;
    
        ts(2).name   = 'coding-h';
        ts(2).class  = -1;
        data         = pseudo1(1023:end,:);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(2).data   = data;

        ts(3).name   = 'other-ncrna';
        ts(3).class  = -1;
        data         = pseudo2(101:end,:);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(3).data   = data;

        ts(4).name   = 'mirbase12-nh';
        ts(4).class  = 1;
        data         = loadset('mirbase12','non-human',7);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(4).data   = data;
        
        ts(5).name   = 'mirbase20-h';
        ts(5).class  = 1;
        data         = loadset('mirbase20','human',6);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(5).data   = data;

        ts(6).name   = 'mirbase20-nh';
        ts(6).class  = 1;
        data         = loadset('mirbase20','non-human',7);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(6).data   = data;
    
    elseif strcmpi(id,'batuwita-multi')

        real0   = stshuffle(loadset('mirbase12-micropred/multi', 'human', 0)); % 691  hsa
        pseudo1 = stshuffle(loadset('coding', 'all', 2));            % 8494 hsa
        pseudo2 = stshuffle(loadset('other-ncrna/multi', 'all', 3)); % 754  hsa

        % NOTE: as there is not a train/test ratio specified on paper,
        % we set to consider 85% of real1 for training
        % and pseudo1 proportionally as well
        
        real   = real0(1:587,:);    % 587 real for training
        pseudo = stshuffle([pseudo1(1:1070,:);pseudo2(1:104,:)]); % 1174 pseudo

        % scale the data to the range [-1:1]
        [real(:,1:66) f s] = scalefun(real(:,1:66));
        [pseudo(:,1:66)]   = scalefun(pseudo(:,1:66),f,s);

        tr.real   = real;
        tr.pseudo = pseudo;
        
        tr.scale_f = f;
        tr.scale_s = s;        
    
        % test datasets (not used for CV)
        ts(1).name   = 'mirbase12-h';
        ts(1).class  = 1;
        data         = real0( 588:end,:);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(1).data   = data;
    
        ts(2).name   = 'coding-h';
        ts(2).class  = -1;
        data         = pseudo1(1071:end,:);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(2).data   = data;

        ts(3).name   = 'other-ncrna';
        ts(3).class  = -1;
        data         = pseudo2(105:end,:);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(3).data   = data;

        ts(4).name   = 'mirbase12-nh';
        ts(4).class  = 1;
        data         = loadset('mirbase12/multi','non-human',7);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(4).data   = data;
        
        ts(5).name   = 'mirbase20-h';
        ts(5).class  = 1;
        data         = loadset('mirbase20/multi','human',6);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(5).data   = data;

        ts(6).name   = 'mirbase20-nh';
        ts(6).class  = 1;
        data         = loadset('mirbase20/multi','non-human',7);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(6).data   = data;
    
    end
        
end