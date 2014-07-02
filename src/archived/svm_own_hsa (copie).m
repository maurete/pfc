function svm_own_hsa
    
    % keep record of this experiment for review
    rec = struct();
    
    %rec.random_seed = 562549009;
    rec.random_seed = 562345829;
    
    rec.num_partitions = 5;
    rec.num_iterations = 5;
    rec.grid_refine = 5;
    rec.initial_sigma = exp([-15:2:15]');
    rec.initial_boxconstraint = exp([-0:2:14]);
        
    % load train datasets
    real1   = loadset('mirbase20-nr','human', 0); % 1265 hsa entries
    pseudo1 = loadset('coding','all', 1);      % 8494 hsa-only dataset
    pseudo2 = loadset('other-ncrna','all', 2); % 129  hsa-only dataset

    % test datasets (not used for CV)
    rec.test = struct();
    rec.test(1).name  = 'mirbase20-other-species';
    rec.test(1).class = 1;
    rec.test(1).data  = loadset('mirbase20-nr','non-human', 3);
    
    % aux functions
    pick    = @(x,n) x(randsample(size(x,1),min(size(x,1),n)),:);
    shuffle = @(x)   x(randsample(size(x,1),size(x,1)),:);
    stpick    = @(x,n) x(strandsample(rec.random_seed,size(x,1),min(size(x,1),n)),:);
    stshuffle = @(x)   x(strandsample(rec.random_seed,size(x,1),size(x,1)),:);
    
    % pick random elements for training with ratio 1real:2pseudo
    real   = stpick(real1, 1260); % 1260 real
    pseudo = stshuffle([ stpick(pseudo1,2391); pseudo2 ]); % 2520 pseudo
    
    % scale the data to the range [-1:1]
    [real(:,1:66) f s] = scale_data(real(:,1:66));
    [pseudo(:,1:66)]   = scale_data(pseudo(:,1:66),f,s);

    rec.scale_f = f;
    rec.scale_s = s;
    
    % generate 10 cross-validation partitions
    [tr_real ts_real]     = stpart(rec.random_seed, real, rec.num_partitions);
    [tr_pseudo ts_pseudo] = stpart(rec.random_seed, pseudo, rec.num_partitions);
    
    fprintf('REAL %d PSEUDO %d TR+ %d TR- %d TE+ %d TE- %d\n', ...
            size(real,1), size(pseudo,1), size(tr_real,1), ...
            size(tr_pseudo,1), size(ts_real,1), size(ts_pseudo, 1))
    
    % create matlab pool
    num_workers = 12;
    if matlabpool('size') == 0
        while( num_workers > 1 )
            try
                matlabpool(num_workers);
                break
            catch e
                num_workers = num_workers-1;
                fprintf(['not supported, trying with %d workers..\n'], num_workers);
            end
        end
    end

    rec.begintime = clock;
    rec.time = 0;
    rec.numcv = 0;
    fprintf('Beginning at %d-%d-%d %02d:%02d.\n', rec.begintime(1:5))

    % initial sigma-boxconstraint values for grid search
    rec.gs = struct();
    rec.gs(1).sigma = rec.initial_sigma;
    rec.gs(1).boxconstraint = rec.initial_boxconstraint;
    
    % refine sigma-bc
    for r=1:rec.grid_refine
      fprintf('Step %d crossval with %d parameter combinations.\n', ...
              r, length(rec.gs(r).sigma)*length(rec.gs(r).boxconstraint))
      if r>1
          esttime = round(rec.time/rec.numcv*length(rec.gs(r).sigma)*length(rec.gs(r).boxconstraint));
          estendt = datevec(datenum(0,0,0,0,0,esttime)+now);
          fprintf('This will take about %dm %ds, ending at %02d:%02d.\n', ...
                  floor(esttime/60), mod(esttime,60), fix(estendt(4:5)))
      end
      
      % avoid nested loops linearizing Z-C matrix
      rec.gs(r).l_sigma = reshape( diag(rec.gs(r).sigma)*ones(length(rec.gs(r).sigma),...
                                                       length(rec.gs(r).boxconstraint)), 1, []);
      rec.gs(r).l_boxc  = reshape( ones(length(rec.gs(r).sigma),...
                                 length(rec.gs(r).boxconstraint))*diag(rec.gs(r).boxconstraint), 1, []);

      % aux variables for the parallel loop -- avoid passing struct
      se_ = zeros( rec.num_iterations, length(rec.gs(r).l_boxc) ); % sensitivity
      sp_ = zeros( rec.num_iterations, length(rec.gs(r).l_boxc) ); % specificity
      gm_ = zeros( rec.num_iterations, length(rec.gs(r).l_boxc) ); % se-sp geometric mean
      ignore = zeros(size(rec.gs(r).l_sigma));

      rec.gs(r).iter = struct();
      for t=1:rec.num_iterations
          
          % shuffle data and separate labels
          train_data = shuffle( [  real(  tr_real(:,mod(t,rec.num_partitions)+1),:); ...
                                 pseudo(tr_pseudo(:,mod(t,rec.num_partitions)+1),:)] );

          rec.gs(r).iter(t).train_ids  = train_data(:,68:70);
          train_lbls = train_data(:,67);
          rec.gs(r).iter(t).train_lbls  = train_lbls;          
          train_data = train_data(:,1:66);
          
          test_real   =   real(  ts_real(:,mod(t,rec.num_partitions)+1),1:66);
          test_pseudo = pseudo(ts_pseudo(:,mod(t,rec.num_partitions)+1),1:66);

          rec.gs(r).iter(t).test_real_ids   =   real(  ts_real(:,mod(t,rec.num_partitions)+1),68:70);
          rec.gs(r).iter(t).test_pseudo_ids = pseudo(ts_pseudo(:,mod(t,rec.num_partitions)+1),68:70);
          
          sav = struct();
          for n=1:length(rec.gs(r).l_sigma)
              sav(n).feat = struct();
              for nf=1:5
                  sav(n).feat(nf).model = [];
                  sav(n).feat(nf).re    = [];
                  sav(n).feat(nf).ps    = [];              
              end
          end % for n
          
          %     1-66: feature vector:
          %             1-32 - triplet features (.3)
          %            33-36 - triplet-extra features (.3x)
          %            37-59 - sequence features (.s)
          %            60-66 - folding features (.f)
          %       67: entry class (1, 0 or -1)
          
          parfor n=1:length(rec.gs(r).l_sigma)
              if ignore(n) continue; end
              idx = [1,66;1,32;33,36;37,59;60,66];
              for f=1:5

                  try
                      model = svmtrain(train_data(:,idx(f,1):idx(f,2)),train_lbls, ...
                                       'Kernel_Function','rbf', ...
                                       'rbf_sigma',rec.gs(r).l_sigma(n), ...
                                       'boxconstraint',rec.gs(r).l_boxc(n));

                      res_r = round(svmclassify(model, test_real(:,idx(f,1):idx(f,2))));
                      res_p = round(svmclassify(model, test_pseudo(:,idx(f,1):idx(f,2))));
                      
                      if f == 1
                          se_(t,n) = mean( res_r == 1 );
                          sp_(t,n) = mean( res_p == -1 );
                          gm_(t,n) = geomean( [se_(t,n) sp_(t,n)] );

                          % ignore this paramset if it's too bad
                          if gm_(t,n) < 0.8
                              ignore(n) = 1;
                              continue
                          end
                      end
                      
                      % save only 'good' models
                      if gm_(t,n) > 0.8
                          sav(n).feat(f).model = model;
                          sav(n).feat(f).re = res_r;
                          sav(n).feat(f).ps = res_p;
                      end
                      
                  catch e
                      % ignore this paramset if it does not converge
                      if strfind(e.identifier,'NoConvergence')
                          if f == 1
                              ignore(n) = 1;
                          end
                      else
                          fprintf('err: %s / %s', e.identifier, e.message)
                      end
                  end % try
              end % for f
          end % parfor n
          
          rec.gs(r).iter(t).paramtest = struct();
          for n=1:length(rec.gs(r).l_sigma)
              rec.gs(r).iter(t).paramtest(n).model = sav(n).feat(1).model;
              rec.gs(r).iter(t).paramtest(n).results_real = sav(n).feat(1).re;
              rec.gs(r).iter(t).paramtest(n).results_pseudo = sav(n).feat(1).ps;
              rec.gs(r).iter(t).paramtest(n).sensitivity = se_(t,n);
              rec.gs(r).iter(t).paramtest(n).specificity = sp_(t,n);
              rec.gs(r).iter(t).paramtest(n).geomean     = gm_(t,n);
              rec.gs(r).iter(t).paramtest(n).ignored     = ignore(n);             
          end % for n
          
      end % for t

      rec.gs(r).se = se_;
      rec.gs(r).sp = sp_;
      rec.gs(r).gm = gm_;
      
      % aux vars
      mgm = mean(rec.gs(r).gm,1);
      mse = mean(rec.gs(r).se,1);
      msp = mean(rec.gs(r).sp,1);
      
      % pick best parameters
      rec.gs(r).best = [ abs(mgm-max(mgm)) < 4^(-r-2) ];
      
      % refine grid around central value n
      neighbor = @(n,d,w) exp([log(n)-w/2^(d-1):1/2^(d-1):log(n)+w/2^(d-1)]);
            
      % new parameters for next iter
      ns = [];
      nc = [];
      for d=find(rec.gs(r).best)
          fprintf('Step %d: SE %8.6f SP %8.6f GM %8.6f for log(Z,C) = %8.6f,%8.6f idx %d\n', ...
                  r, mse(d), msp(d), mgm(d), log(rec.gs(r).l_sigma(d)), log(rec.gs(r).l_boxc(d)),d);
          % append new values to ns,nc
          ns = [ ns; neighbor(rec.gs(r).l_sigma(d),r,4)'];
          nc = [ nc, neighbor(rec.gs(r).l_boxc(d), r,4) ];
      end % for d
      
      % delete non-best svm models as they take up too much space
      for n=find(1-rec.gs(r).best)
          for t=1:rec.num_iterations
              rec.gs(r).iter(t).paramtest(n).model = 'discarded';
          end
      end

      % values for next grid refine
      if r < rec.grid_refine
          rec.gs(r+1).precision = 1/2^(r-1); % as in neighbor function
          rec.gs(r+1).sigma         = logunique( ns, 1e-5 );
          rec.gs(r+1).boxconstraint = logunique( nc, 1e-5 );
      end
      
      rec.numcv = rec.numcv + length(rec.gs(r).sigma)*length(rec.gs(r).boxconstraint);
      rec.time = round(etime(clock,rec.begintime));
      fprintf( 'Time: %02d:%02d.\n', floor(rec.time/60), mod(rec.time,60))
    
    end % for r    
    % matlabpool close

    % perform classification on test datasets
    bidx = find(rec.gs(rec.grid_refine).best,1,'first');    
    for i=1:length(rec.test)
        rec.test(i).cls_results = zeros(size(rec.test(i).data,1),rec.num_iterations); 
        rec.test(i).performance = zeros(1,rec.num_iterations); 

        scaled = scale_data(rec.test(i).data(:,1:66),rec.scale_f,rec.scale_s);
        for t=1:rec.num_iterations
            model = rec.gs(rec.grid_refine).iter(t).paramtest(bidx).model;
            rec.test(i).cls_results(:,t) = round(svmclassify(model, scaled));
            rec.test(i).performance(t)   = mean(rec.test(i).cls_results(:,t) == rec.test(i).class);
        end
        rec.test(i).avg_performance = mean(rec.test(i).performance); 

        fprintf('test dataset %s: %d entries, avg performance %8.6f.\n',...
                rec.test(i).name, size(rec.test(i).data,1), rec.test(i).avg_performance);
        
        % clear data for saving space
        rec.test(i).data = [];
    end
    
    save( ['rec_svm_own_hsa-' datestr(rec.begintime,'yyyy-mm-dd_HH.MM.SS') '.mat'],'-struct', 'rec');

end
