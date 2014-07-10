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
    if strcmpi(id,'hsa')
        real1   = loadset('mirbase20-nr','human', 0); % 1265 hsa entries
        pseudo1 = loadset('coding','all', 1);         % 8494 hsa-only dataset
        pseudo2 = loadset('other-ncrna','all', 2);    % 129  hsa-only dataset

        coding  = stshuffle(pseudo1);
        real0   = stshuffle(real1);
        
        % pick random elements for training with ratio 1real:2pseudo
        real   = real0(1:1200,:); % 1200 real
        pseudo = stshuffle([ coding(1:2271,:); pseudo2 ]); % 2400 pseudo

        % scale the data to the range [-1:1]
        [real(:,1:66) f s] = scalefun(real(:,1:66));
        [pseudo(:,1:66)]   = scalefun(pseudo(:,1:66),f,s);

        tr.real = real;
        tr.pseudo = pseudo;
        
        tr.scale_f = f;
        tr.scale_s = s;

        % test datasets (not used for CV)
        ts(1).name   = 'mirbase20-other-species';
        ts(1).class  = 1;
        data         = loadset('mirbase20-nr','non-human', 3);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(1).data   = data;

        ts(2).name   = 'mirbase20-human-notrain';
        ts(2).class  = 1;
        data         = real0(1201:end,:);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(2).data   = data;

        ts(3).name   = 'coding-human-notrain';
        ts(3).class  = -1;
        data         = coding(2272:end,:);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(3).data   = data;
        
    elseif strcmpi(id,'all')

        real1   = stshuffle(loadset('mirbase20-nr','all', 0));     % 13070 all-species
        pseudo1 = stshuffle(loadset('functional-ncrna','all', 1)); % 2650 all-species
        pseudo2 = stshuffle(loadset('coding','all', 2));           % 8494 hsa
        
        real   = real1(1:2200,:); % 2200 real for training
        pseudo = pseudo1(1:2200,:);
        %stshuffle([ pseudo1(1:2200,:); pseudo2(1:2200,:) ]); % 4400 pseudo

        % scale the data to the range [-1:1]
        [real(:,1:66) f s] = scalefun(real(:,1:66));
        [pseudo(:,1:66)]   = scalefun(pseudo(:,1:66),f,s);

        tr.real = real;
        tr.pseudo = pseudo;
        
        tr.scale_f = f;
        tr.scale_s = s;        
    
        % test datasets (not used for CV)
        ts(1).name   = 'mirbase20-human-notrain';
        ts(1).class  = 1;
        data         = real1( 2201:end,:);
        data         = data(find(real1(2201:end,69)==97),:);
        %data(:,70)   = 3*ones(size(data,1),1);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(1).data   = data;

        ts(2).name   = 'mirbase20-nonhuman-notrain';
        ts(2).class  = 1;
        data         = real1( 2201:end,:);
        data         = data(find(real1(2201:end,69)~=97),:);
        %data(:,70)   = 4*ones(size(data,1),1);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(2).data   = data;
    
        ts(3).name   = 'coding-human';
        ts(3).class  = -1;
        data         = pseudo2;
        %data(:,70)   = 5*ones(size(data,1),1);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(3).data   = data;
    
        ts(4).name   = 'functional-ncrna-human-notrain';
        ts(4).class  = -1;
        data         = pseudo1(2201:end,:);
        %data(:,70)   = 5*ones(size(data,1),1);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(4).data   = data;
 
        ts(5).name   = 'other-ncrna-human';
        ts(5).class  = -1;
        data         = loadset('other-ncrna', 'all', 55);;
        %data(:,70)   = 5*ones(size(data,1),1);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(5).data   = data;
     
    elseif strcmpi(id,'xue')

        real1   = loadset('mirbase50', 'human', 0);         % 193  hsa
        real2   = loadset('mirbase50', 'non-human', 1);   % ???  other
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
        ts(1).name   = 'mirbase50-human-notrain';
        ts(1).class  = 1;
        data         = real0( 164:end,:);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(1).data   = data;

        ts(2).name   = 'mirbase50-nonhuman-notrain';
        ts(2).class  = 1;
        data         = real2;
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(2).data   = data;
    
        ts(3).name   = 'updated-human-notrain';
        ts(3).class  = 1;
        data         = real3;
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(3).data   = data;

        ts(4).name   = 'coding-human-notrain';
        ts(4).class  = -1;
        data         = stpick(pseudo0(169:end,:),1000);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(4).data   = data;

        ts(5).name   = 'conserved-hairpin-human-notrain';
        ts(5).class  = -1;
        data         = pseudo2;
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(5).data   = data;

        ts(6).name   = 'mirbase20-human';
        ts(6).class  = 1;
        data         = loadset('mirbase20-nr','human',6);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(6).data   = data;

        ts(7).name   = 'mirbase20-non-human';
        ts(7).class  = 1;
        data         = loadset('mirbase20-nr','non-human',7);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(7).data   = data;

        
    elseif strcmpi(id,'ng')

        real1   = loadset('mirbase82-nr', 'human', 0);       % ???  hsa
        real2   = loadset('mirbase82-nr', 'non-human', 1); % ???  other
        pseudo1 = loadset('coding', 'all', 2);             % 8494 hsa
        pseudo2 = loadset('functional-ncrna', 'all', 3);   % ???  all

        real0   = stshuffle(real1);
        pseudo0 = stshuffle(pseudo1);
        
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
        ts(1).name   = 'mirbase82-human-notrain';
        ts(1).class  = 1;
        data         = real0( 201:end,:);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(1).data   = data;

        ts(2).name   = 'mirbase82-nonhuman-notrain';
        ts(2).class  = 1;
        data         = real2;
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(2).data   = data;
    
        ts(3).name   = 'coding-human-notrain';
        ts(3).class  = -1;
        data         = pseudo0(401:end,:); % original = 246 + 3836
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(3).data   = data;

        ts(4).name   = 'functional-ncrna-allsp-notrain';
        ts(4).class  = -1;
        data         = pseudo2;
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(4).data   = data;

        ts(5).name   = 'mirbase20-human';
        ts(5).class  = 1;
        data         = loadset('mirbase20-nr','human',6);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(5).data   = data;

        ts(6).name   = 'mirbase20-non-human';
        ts(6).class  = 1;
        data         = loadset('mirbase20-nr','non-human',7);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(6).data   = data;
        
    elseif strcmpi(id,'batuwita')

        real1   =           loadset('mirbase12', 'human', 0);       % ???  hsa
        % real2   =           loadset('mirbase12', 'non-human', 1); % ???  other
        pseudo1 = stshuffle(loadset('coding', 'all', 2));         % 8494 hsa
        pseudo2 = stshuffle(loadset('other-ncrna', 'all', 3));    % ???  hsa

        real0   = stshuffle(real1);
        
        % NOTE: as there is not a train/test ratio specified on paper,
        % we set to consider 85% of real1 for training
        % and pseudo1 proportionally as well
        
        real   = real0(1:561,:);    % 561 real for training
        pseudo = stshuffle([pseudo1(1:1012,:);pseudo2(1:110,:)]); % 1122 pseudo

        % scale the data to the range [-1:1]
        [real(:,1:66) f s] = scalefun(real(:,1:66));
        [pseudo(:,1:66)]   = scalefun(pseudo(:,1:66),f,s);

        tr.real   = real;
        tr.pseudo = pseudo;
        
        tr.scale_f = f;
        tr.scale_s = s;        
    
        % test datasets (not used for CV)
        ts(1).name   = 'mirbase12-human-notrain';
        ts(1).class  = 1;
        data         = real0( 562:end,:);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(1).data   = data;
    
        ts(2).name   = 'coding-human-notrain';
        ts(2).class  = -1;
        data         = pseudo1(1013:end,:);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(2).data   = data;

        ts(3).name   = 'other-ncrna-human-notrain';
        ts(3).class  = -1;
        data         = pseudo2(111:end,:);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(3).data   = data;

        ts(4).name   = 'mirbase20-human';
        ts(4).class  = 1;
        data         = loadset('mirbase20-nr','human',6);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(4).data   = data;

        ts(5).name   = 'mirbase20-non-human';
        ts(5).class  = 1;
        data         = loadset('mirbase20-nr','non-human',7);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(5).data   = data;

    elseif strcmpi(id,'all+coding')

        real1   = stshuffle(loadset('mirbase20-nr','all', 0));     % 13070 all-species
        pseudo1 = stshuffle(loadset('functional-ncrna','all', 1)); % 2650 all-species
        pseudo2 = stshuffle(loadset('coding','all', 2));           % 8494 hsa
        
        real   = real1(1:1200,:); % 1200 real for training
        pseudo = stshuffle( [ pseudo1(1:1200,:); pseudo2(1:1200,:) ] ); % 2400 pseudo

        % scale the data to the range [-1:1]
        [real(:,1:66) f s] = scalefun(real(:,1:66));
        [pseudo(:,1:66)]   = scalefun(pseudo(:,1:66),f,s);

        tr.real = real;
        tr.pseudo = pseudo;
        
        tr.scale_f = f;
        tr.scale_s = s;        
    
        % test datasets (not used for CV)
        ts(1).name   = 'mirbase20-human-notrain';
        ts(1).class  = 1;
        data         = real1( 1201:end,:);
        data         = data(find(real1(1201:end,69)==97),:);
        %data(:,70)   = 3*ones(size(data,1),1);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(1).data   = data;

        ts(2).name   = 'mirbase20-nonhuman-notrain';
        ts(2).class  = 1;
        data         = real1( 1201:end,:);
        data         = data(find(real1(1201:end,69)~=97),:);
        %data(:,70)   = 4*ones(size(data,1),1);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(2).data   = data;
    
        ts(3).name   = 'coding-human-notrain';
        ts(3).class  = -1;
        data         = pseudo2(1201:end,:);
        %data(:,70)   = 5*ones(size(data,1),1);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(3).data   = data;
    
        ts(4).name   = 'functional-ncrna-human-notrain';
        ts(4).class  = -1;
        data         = pseudo1(1201:end,:);
        %data(:,70)   = 5*ones(size(data,1),1);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(4).data   = data;
 
        ts(5).name   = 'other-ncrna-human';
        ts(5).class  = -1;
        data         = loadset('other-ncrna', 'all', 55);;
        %data(:,70)   = 5*ones(size(data,1),1);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(5).data   = data;
    
    elseif strcmpi(id,'all+human')

        real1   = stshuffle(loadset('mirbase20-nr','human', 0));     % 13070 all-species
        real2   = stshuffle(loadset('mirbase20-nr','non-human', 1));     % 13070 all-species
        pseudo1 = stshuffle(loadset('functional-ncrna','all', 2)); % 2650 all-species
        pseudo2 = stshuffle(loadset('coding','all', 3));           % 8494 hsa
        
        real   = stshuffle( [ real1(1:600,:); real2(1:600,:) ] ); % 1200 real for training
        pseudo = stshuffle( [ pseudo1(1:1200,:); pseudo2(1:1200,:) ] ); %2400 pseudo 

        % scale the data to the range [-1:1]
        [real(:,1:66) f s] = scalefun(real(:,1:66));
        [pseudo(:,1:66)]   = scalefun(pseudo(:,1:66),f,s);

        tr.real = real;
        tr.pseudo = pseudo;
        
        tr.scale_f = f;
        tr.scale_s = s;        
    
        % test datasets (not used for CV)
        ts(1).name   = 'mirbase20-human-notrain';
        ts(1).class  = 1;
        data         = real1( 601:end,:);
        %data(:,70)   = 3*ones(size(data,1),1);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(1).data   = data;

        ts(2).name   = 'mirbase20-nonhuman-notrain';
        ts(2).class  = 1;
        data         = real2( 601:end,:);
        %data(:,70)   = 4*ones(size(data,1),1);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(2).data   = data;
    
        ts(3).name   = 'coding-human-notrain';
        ts(3).class  = -1;
        data         = pseudo2(1201:end,:);
        %data(:,70)   = 5*ones(size(data,1),1);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(3).data   = data;
    
        ts(4).name   = 'functional-ncrna-allsp-notrain';
        ts(4).class  = -1;
        data         = pseudo1(1201:end,:);
        %data(:,70)   = 5*ones(size(data,1),1);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(4).data   = data;
 
        ts(5).name   = 'other-ncrna-human';
        ts(5).class  = -1;
        data         = loadset('other-ncrna', 'all', 55);;
        %data(:,70)   = 5*ones(size(data,1),1);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(5).data   = data;
    
    elseif strcmpi(id,'ng-multi')

        real0   = stshuffle(loadset('mirbase82-nr-multi', 'human', 0));     % ???  hsa
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
        ts(1).name   = 'mirbase82-human-notrain';
        ts(1).class  = 1;
        data         = real0( 201:end,:);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(1).data   = data;

        ts(2).name   = 'mirbase82-nonhuman-notrain';
        ts(2).class  = 1;
        data         = loadset('mirbase82-nr-multi', 'non-human', 1);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(2).data   = data;
    
        ts(3).name   = 'coding-human-notrain';
        ts(3).class  = -1;
        data         = pseudo0(401:end,:); % original = 246 + 3836
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(3).data   = data;

        ts(4).name   = 'functional-ncrna-allsp-notrain';
        ts(4).class  = -1;
        data         = loadset('functional-ncrna-multi', 'all', 3);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(4).data   = data;

        ts(5).name   = 'mirbase20-human';
        ts(5).class  = 1;
        data         = loadset('mirbase20-nr-multi','human',6);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(5).data   = data;

        ts(6).name   = 'mirbase20-non-human';
        ts(6).class  = 1;
        data         = loadset('mirbase20-nr-multi','non-human',7);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(6).data   = data;

    elseif strcmpi(id,'batuwita-multi')

        real1   =           loadset('mirbase12-multi', 'human', 0); % 691  hsa
        pseudo1 = stshuffle(loadset('coding', 'all', 2));           % 8494 hsa
        pseudo2 = stshuffle(loadset('other-ncrna', 'all', 3));      % 754  hsa

        real0   = stshuffle(real1);
        
        % NOTE: as there is not a train/test ratio specified on paper,
        % we set to consider 85% of real1 for training
        % and pseudo1 proportionally as well
        
        real   = real0(1:587,:);    % 587 real for training
        pseudo = stshuffle([pseudo1(1:1056,:);pseudo2(1:118,:)]); % 1174 pseudo

        % scale the data to the range [-1:1]
        [real(:,1:66) f s] = scalefun(real(:,1:66));
        [pseudo(:,1:66)]   = scalefun(pseudo(:,1:66),f,s);

        tr.real   = real;
        tr.pseudo = pseudo;
        
        tr.scale_f = f;
        tr.scale_s = s;        
    
        % test datasets (not used for CV)
        ts(1).name   = 'mirbase12-human-notrain';
        ts(1).class  = 1;
        data         = real0( 588:end,:);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(1).data   = data;
    
        ts(2).name   = 'coding-human-notrain';
        ts(2).class  = -1;
        data         = pseudo1(1057:end,:);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(2).data   = data;

        ts(3).name   = 'other-ncrna-human-notrain';
        ts(3).class  = -1;
        data         = pseudo2(119:end,:);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(3).data   = data;

        ts(4).name   = 'mirbase20-human';
        ts(4).class  = 1;
        data         = loadset('mirbase20-nr-multi','human',6);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(4).data   = data;

        ts(5).name   = 'mirbase20-non-human';
        ts(5).class  = 1;
        data         = loadset('mirbase20-nr-multi','non-human',7);
        data(:,1:66) = scalefun(data(:,1:66),f,s);
        ts(5).data   = data;
    
    end
        
end