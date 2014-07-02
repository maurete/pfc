function svm_quad_hsa
    
    % keep record of this experiment for review
    rec = struct();
    
    %rec.random_seed = 562549009;
    %rec.random_seed = 562345829;
    rec.random_seed = mod(5829,2^32);    
    
    % feature sets with which to train: 
    % 1=all, 2=triplet, 3=triplet-extra, 
    % 4=sequence, 5=structure
    rec.featsets = 1;
    
    rec.num_partitions = 5;
    rec.num_iterations = 5;
    rec.grid_refine    = 5;
    %rec.initial_sigma         = exp([-15:2:15]');
    rec.initial_boxconstraint = exp([-6:2:20]);
    
    % aux functions
    pick      = @(x,n) x(randsample(size(x,1),min(size(x,1),n)),:);
    shuffle   = @(x)   x(randsample(size(x,1),size(x,1)),:);
    stpick    = @(x,n) x(strandsample(rec.random_seed,size(x,1),min(size(x,1),n)),:);
    stshuffle = @(x)   x(strandsample(rec.random_seed,size(x,1),size(x,1)),:);
    function o=zerofill(i),o=0;if i,o=i;end,end
    
    % load train datasets
    real1   = loadset('mirbase20-nr','human', 0); % 1265 hsa entries
    pseudo1 = loadset('coding','all', 1);         % 8494 hsa-only dataset
    pseudo2 = loadset('other-ncrna','all', 2);    % 129  hsa-only dataset

    % test datasets (not used for CV)
    rec.test = struct();
    rec.test(1).name  = 'mirbase20-other-species';
    rec.test(1).class = 1;
    rec.test(1).data  = loadset('mirbase20-nr','non-human', 3);

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
                fprintf(['trying %d workers..\n'], num_workers);
            end
        end
    end

    rec.begintime = clock;
    rec.time = 0;
    rec.numcv = 0;
    fprintf('Beginning at %d-%d-%d %02d:%02d.\n', rec.begintime(1:5))

    % initial sigma-boxconstraint values for grid search
    rec.gs = struct();
    %rec.gs(1).sigma = rec.initial_sigma;
    rec.gs(1).boxconstraint = rec.initial_boxconstraint;
    
    % refine sigma-bc
    for r=1:rec.grid_refine
      fprintf('Step %d crossval with %d parameter combinations.\n', ...
              r, length(rec.gs(r).boxconstraint))
      if r>1
          esttime = round(rec.time/rec.numcv*length(rec.gs(r).boxconstraint));
          estendt = datevec(datenum(0,0,0,0,0,esttime)+now);
          fprintf('This will take about %dm %ds, ending at %02d:%02d.\n', ...
                  floor(esttime/60), mod(esttime,60), fix(estendt(4:5)))
      end
      
      %rec.gs(r).l_boxc  = reshape( ones(length(rec.gs(r).sigma),...
      %                           length(rec.gs(r).boxconstraint))*diag(rec.gs(r).boxconstraint), 1, []);

      N = length(rec.gs(r).boxconstraint);
      T = rec.num_iterations;

      % results for current r
      res = cell(N,T,5,6);
      
      % ignore flag, avoid trying nonconvergent values
      ignore = zeros(size(rec.gs(r).boxconstraint));

      % details for each iteration
      rec.gs(r).iter = struct();

      % featureset indexes
      fidx = [1,66;1,32;33,36;37,59;60,66];
      
      for t=1:T
          
          % shuffle data and separate labels
          train_data = shuffle( [  real(  tr_real(:,mod(t,rec.num_partitions)+1),:); ...
                                 pseudo(tr_pseudo(:,mod(t,rec.num_partitions)+1),:)] );

          rec.gs(r).iter(t).train_ids  = train_data(:,68:70);
          train_lbls                   = train_data(:,67);
          rec.gs(r).iter(t).train_lbls = train_lbls;          
          train_data                   = train_data(:,1:66);
          
          test_real   =   real(  ts_real(:,mod(t,rec.num_partitions)+1),1:66);
          test_pseudo = pseudo(ts_pseudo(:,mod(t,rec.num_partitions)+1),1:66);

          rec.gs(r).iter(t).test_real_ids   =   real(  ts_real(:,mod(t,rec.num_partitions)+1),68:70);
          rec.gs(r).iter(t).test_pseudo_ids = pseudo(ts_pseudo(:,mod(t,rec.num_partitions)+1),68:70);
          
          parfor n=1:N
              if ignore(n) continue; end
              auxr = res(n,:,:,:);
              for f=rec.featsets
                  try
                      model = svmtrain(train_data(:,fidx(f,1):fidx(f,2)),train_lbls, ...
                                       'Kernel_Function','quadratic', ...
                                       'boxconstraint',rec.gs(r).boxconstraint(n));

                      res_r = round(svmclassify(model, test_real(:,fidx(f,1):fidx(f,2))));
                      res_p = round(svmclassify(model, test_pseudo(:,fidx(f,1):fidx(f,2))));
                      
                      Se = mean( res_r == 1 );
                      Sp = mean( res_p == -1 );
                      Gm = geomean( [Se Sp] );

                      auxr(1,t,f,1:3) = { Se, Sp, Gm };

                      % ignore this paramset if it's too bad
                      if Gm < 0.6
                          ignore(n) = 1;
                          continue
                      end
                      
                      % save only 'good' models
                      if Gm > 0.8
                          auxr(1,t,f,4:6) = { res_r, res_p, model };
                      end
                                            
                  catch e
                      % ignore this paramset if it does not converge
                      if strfind(e.identifier,'NoConvergence')
                          if f == 1
                              ignore(n) = 1;
                          end
                      elseif strfind(e.identifier,'InvalidInput')
                          if f == 1
                              ignore(n) = 1;
                          end
                      else
                          fprintf('err: %s / %s', e.identifier, e.message)
                      end
                  end % try
              end % for f
              
              % save results to cell array
              res(n,:,:,:) = auxr;
          end % parfor n

          rec.gs(r).raw_results = res;
      end % for t

      rec.gs(r).feat = struct();
      avgbest = zeros(5,N);
      
      % for every feature
      for f = rec.featsets
          % save avg performance
          rec.gs(r).feat(f).se = mean( cellfun(@zerofill,res(:,:,f,1)'), 1);
          rec.gs(r).feat(f).sp = mean( cellfun(@zerofill,res(:,:,f,2)'), 1);
          rec.gs(r).feat(f).gm = mean( cellfun(@zerofill,res(:,:,f,3)'), 1);
          % highlight best-performing paramsets
          rec.gs(r).feat(f).best = [ abs(rec.gs(r).feat(f).gm-max(rec.gs(r).feat(f).gm)) < 4^(-r-2) ];

          for d=find(rec.gs(r).feat(f).best)
              fprintf('Step %d, feat %d: SE %8.6f SP %8.6f GM %8.6f for log(C) = %8.6f idx %d\n', ...
                  r, f, rec.gs(r).feat(f).se(d), rec.gs(r).feat(f).sp(d), rec.gs(r).feat(f).gm(d), ...
                  log(rec.gs(r).boxconstraint(d)),d);
          end % for d
          
          % fill column of average-best matrix
          avgbest(f,:) = rec.gs(r).feat(f).best;
      end
      avgbest = mean(avgbest(rec.featsets,:),1);

      % pick best parameters
      rec.gs(r).best = [ abs(avgbest-max(avgbest)) < 0.1 ];
      
      % refine grid around central value n
      neighbor = @(n,d,w) exp([log(n)-w/2^(d-1):1/2^(d-1):log(n)+w/2^(d-1)]);
            
      % new parameters for next iteration
      nc = [];
      for d=find(rec.gs(r).best)
          fprintf('Step %d: SE %8.6f SP %8.6f GM %8.6f for log(C) = %8.6f idx %d\n', ...
                  r, rec.gs(r).feat(rec.featsets(1)).se(d), ...
                  rec.gs(r).feat(rec.featsets(1)).sp(d), ...
                  rec.gs(r).feat(rec.featsets(1)).gm(d), ...
                  log(rec.gs(r).boxconstraint(d)),d);
          % append new values to ns,nc
          nc = [ nc, neighbor(rec.gs(r).boxconstraint(d), r,4) ];
      end % for d
      
      % delete non-best svm models as they take up too much space
      for n=find(1-rec.gs(r).best)
          for t=1:rec.num_iterations
              rec.gs(r).iter(t).paramtest(n).model = 'discarded';
          end
      end

      % values for next grid refine
      if r < rec.grid_refine
          rec.gs(r+1).precision     = 1/2^(r-1); % as in neighbor function
          rec.gs(r+1).boxconstraint = logunique( nc, 1e-5 );
      end
      
      rec.numcv = rec.numcv + length(rec.gs(r).boxconstraint);
      rec.time = round(etime(clock,rec.begintime));
      fprintf( 'Time: %02d:%02d.\n', floor(rec.time/60), mod(rec.time,60))
    
    end % for r    
    % matlabpool close

    % perform classification on test datasets
    bidx = find(rec.gs(rec.grid_refine).best,1,'first');
    
    for i=1:length(rec.test)
        rec.test(i).featset = struct();
        avgperf = [];
        
        scaled = scale_data(rec.test(i).data(:,1:66),rec.scale_f,rec.scale_s);

        for f = rec.featsets
            rec.test(i).featset(f).cls_results = zeros(size(rec.test(i).data,1),rec.num_iterations); 
            rec.test(i).featset(f).performance = zeros(1,rec.num_iterations); 
        
            for t=1:rec.num_iterations
                model = rec.gs(rec.grid_refine).raw_results{bidx,t,f,6};
                rec.test(i).featset(f).cls_results(:,t,f) = round(svmclassify(model, scaled));
                rec.test(i).featset(f).performance(t)     = mean( ...
                    rec.test(i).featset(f).cls_results(:,t) == rec.test(i).class);
            end
            rec.test(i).featset(f).avg_performance =  mean(rec.test(i).featset(f).performance);
            avgperf = [avgperf rec.test(i).featset(f).avg_performance];
        end

        rec.test(i).avg_performance = mean(avgperf); 

        fprintf('test dataset %s: %d entries, avg performance %8.6f.\n',...
                rec.test(i).name, size(rec.test(i).data,1), rec.test(i).avg_performance);
        
        % clear data for saving space
        rec.test(i).data = [];
    end
    
    save( ['./results/svm_quad_hsa-' datestr(rec.begintime,'yyyy-mm-dd_HH.MM.SS') '.mat'],'-struct', 'rec');

end
