function svm_rbf ( dataset, featset, seed )
   
    if nargin < 3
        seed = mod(5829,2^32);
        if nargin < 2
            featset = 1;
            if nargin < 1
                dataset = 'hsa';
            end
        end
    end

    dlm_outfile = 'results.tsv';
    if ~exist( dlm_outfile )
        fid = fopen( dlm_outfile, 'a' );
        fprintf( fid, [ 'id\tseed\ttrain/test\tsetup\tdataset\tfeatset\t'...
                        'classifier\tparam1\tparam2\tse\tsp\tgm/perf\n' ] ); 
        fclose(fid);
    end
    
    fprintf('#\n> begin svm-rbf\n#\n' );
    
    % keep record of this experiment for review
    rec = struct();
    
    %rec.random_seed = 562549009;
    %rec.random_seed = 562345829;
    rec.random_seed = seed;    
    
    % feature sets with which to train: 
    % 1=all, 2=triplet, 3=triplet-extra, 
    % 4=sequence, 5=structure
    rec.feature_set = featset;
    % featureset indexes
    fidx = { 1:66; 1:32; 33:36; 37:59; 60:66; 1:36; [1:36 60:66]; ...
             37:66; 1:59; 33:66; [33:36 60:66]; 33:59; [1:32 60:66]; ...
             [1:32 37:59]; [1:32 37:66] };
    fname = {'all-features', 'triplet', 'triplet-extra', 'sequence', ...
             'structure', 'triplet+extra', 'not-sequence', ...
             'seq+struct', 'not-structure', 'not-triplet', 'extra+str', ...
             'extra+sequence', 'triplet+structure', 'triplet+sequence', ...
             'not-extra' };
    features = fidx{featset};
    
    rec.num_partitions = 5;
    rec.num_iterations = 5;
    rec.grid_refine    = 4;
    rec.initial_sigma         = exp([-15:2:15]');
    rec.initial_boxconstraint = exp([-4:2:14]);
        
    % aux functions
    pick      = @(x,n) x(randsample(size(x,1),min(size(x,1),n)),:);
    shuffle   = @(x)   x(randsample(size(x,1),size(x,1)),:);
    stpick    = @(x,n) x(strandsample(rec.random_seed,size(x,1),min(size(x,1),n)),:);
    stshuffle = @(x)   x(strandsample(rec.random_seed,size(x,1),size(x,1)),:);
    function o=zerofill(i);o=0;if i;o=i;end;end;
           
    rec.begintime = clock;
    rec.time = 0;
    rec.numcv = 0;
    %fprintf('Beginning at %d-%d-%d %02d:%02d.\n', rec.begintime(1:5))
    
    [rec.train rec.test] = load_data( dataset, rec.random_seed);
    
    fprintf('> dataset\t%s\n', dataset );
    fprintf('> featureset\t%s\n', fname{featset} );
    
    real   = rec.train.real;
    pseudo = rec.train.pseudo;
    
    % generate 10 cross-validation partitions
    [tr_real ts_real]     = stpart(rec.random_seed, rec.train.real, rec.num_partitions);
    [tr_pseudo ts_pseudo] = stpart(rec.random_seed, rec.train.pseudo, rec.num_partitions);
    
    fprintf([ '# begin cross-validation training\n> partitions\t%d\n#\n', ...
              '# dataset\tsize\t#train\t#test\n', ...
              '# -------\t----\t------\t-----\n', ...
              '> real\t\t%d\t%d\t%d\n', ...
              '> pseudo\t%d\t%d\t%d\n#\n' ], ...
            rec.num_partitions, size(rec.train.real,1), size(tr_real,1), size(ts_real,1), ...
            size(rec.train.pseudo,1), size(tr_pseudo,1), size(ts_pseudo,1) );
    
    % create matlab pool
    num_workers = 12;
    if matlabpool('size') == 0
        while( num_workers > 1 )
            try
                matlabpool(num_workers);
                break
            catch e
                num_workers = num_workers-1;
                fprintf(['# trying %d workers\n'], num_workers);
            end
        end
    end
    fprintf('# using %d matlabpool workers\n', matlabpool('size'));

    % initial sigma-boxconstraint values for grid search
    rec.gs = struct();
    rec.gs(1).sigma = rec.initial_sigma;
    rec.gs(1).boxconstraint = rec.initial_boxconstraint;
    
    % refine sigma-bc
    for r=1:rec.grid_refine
      fprintf('#\n> gridsearch\t%d\n> parameters\t%d\n', ...
              r, length(rec.gs(r).sigma)*length(rec.gs(r).boxconstraint))
      if r>1
          esttime = round(rec.time/rec.numcv*length(rec.gs(r).sigma)*length(rec.gs(r).boxconstraint));
          estendt = datevec(datenum(0,0,0,0,0,esttime)+now);
          fprintf('# estimated\t%dm %d\tendtime\t%02d:%02d\n', ...
                  floor(esttime/60), mod(esttime,60), fix(estendt(4:5)))
      end
      
      % avoid nested loops by linearizing Z-C matrix
      rec.gs(r).l_sigma = reshape( diag(rec.gs(r).sigma)*ones(length(rec.gs(r).sigma),...
                                                       length(rec.gs(r).boxconstraint)), 1, []);
      rec.gs(r).l_boxc  = reshape( ones(length(rec.gs(r).sigma),...
                                 length(rec.gs(r).boxconstraint))*diag(rec.gs(r).boxconstraint), 1, []);

      N = length(rec.gs(r).l_sigma);
      T = rec.num_iterations;

      % results for current r
      res = cell(N,T,6);
      
      % ignore flag, avoid trying nonconvergent values
      ignore = zeros(size(rec.gs(r).l_sigma));

      % details for each iteration
      rec.gs(r).iter = struct();

      
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
              auxr = res(n,:,:);
              try
                  model = svmtrain(train_data(:,features),train_lbls, ...
                                   'Kernel_Function','rbf', ...
                                   'rbf_sigma',rec.gs(r).l_sigma(n), ...
                                   'boxconstraint',rec.gs(r).l_boxc(n));

                      res_r = round(svmclassify(model, test_real(:,features)));
                      res_p = round(svmclassify(model, test_pseudo(:,features)));
                      
                      Se = mean( res_r == 1 );
                      Sp = mean( res_p == -1 );
                      Gm = geomean( [Se Sp] );

                      auxr(1,t,1:3) = { Se, Sp, Gm };

                      % ignore this paramset if it's too bad
                      if Gm < 0.85
                          ignore(n) = 1;
                          continue
                      end
                      
                      % save only 'good' models
                      if Gm > 0.85
                          auxr(1,t,4:6) = { res_r, res_p, model };
                      end
                                            
                  catch e
                      % ignore this paramset if it does not converge
                      if strfind(e.identifier,'NoConvergence')
                          ignore(n) = 1;
                      elseif strfind(e.identifier,'InvalidInput')
                          ignore(n) = 1;
                      else
                          fprintf('! %s / %s', e.identifier, e.message)
                      end
                  end % try
              
              % save results to cell array
              res(n,:,:) = auxr;
          end % parfor n

          rec.gs(r).raw_results = res;
      end % for t

      % save avg performance
      rec.gs(r).se = mean( cellfun(@zerofill,res(:,:,1)'), 1);
      rec.gs(r).sp = mean( cellfun(@zerofill,res(:,:,2)'), 1);
      rec.gs(r).gm = mean( cellfun(@zerofill,res(:,:,3)'), 1);
      % highlight best-performing paramsets
      rec.gs(r).best = [ abs(rec.gs(r).gm-max(rec.gs(r).gm)) < 4^(-r-2) ];
      
      if max(rec.gs(r).gm) == 0
          fprintf('! no convergence, sorry\n')
          fid = fopen( dlm_outfile, 'a' );
          % fprintf( fid, [ 'id\ttrain/test\tsetup\tdataset\tfeatset\t'...
          %                 'classifier\tparam1\tparam2\tse\tsp\tgm/perf\n' ] ); 
          fprintf( fid, '%f\t%d\t%s\t%s\t%s\t%d\t%s\t%9.8g\t%9.8g\t%9.8g\t%9.8g\t%9.8g\n', ...
                 datenum(rec.begintime), seed, 'train', dataset, 'train', featset, ...
                   'svm-rbf', [], [], 0, 0, 0 );
          for i=1:length(rec.test)
              fprintf( fid, '%f\t%d\t%s\t%s\t%s\t%d\t%s\t%9.8g\t%9.8g\t%9.8g\t%9.8g\t%9.8g\n', ...
                 datenum(rec.begintime), seed, 'test', dataset, rec.test(i).name, featset, ...
                 'svm-rbf', [], [], [], [], 0 );
          end
          fclose(fid)
          return
      end
      
      % for d=find(rec.gs(r).feat(f).best)
      %     fprintf('Step %d, feat %d: SE %8.6f SP %8.6f GM %8.6f for log(Z,C) = %8.6f,%8.6f idx %d\n', ...
      %         r, f, rec.gs(r).feat(f).se(d), rec.gs(r).feat(f).sp(d), rec.gs(r).feat(f).gm(d), ...
      %         log(rec.gs(r).l_sigma(d)), log(rec.gs(r).l_boxc(d)),d);
      % end % for d
                
      % refine grid around central value n
      neighbor = @(n,d,w) exp([log(n)-w/2^(d-1):1/2^(d-1):log(n)+w/2^(d-1)]);
            
      % new parameters for next iteration
      ns = [];
      nc = [];
      fprintf('#\n# idx\tlog(sigma)\tlog(C)\t\tsensitivity\tspecificity\tgeomean\n');
      fprintf(   '# ---\t----------\t------\t\t-----------\t-----------\t-------\n');
      for d=find(rec.gs(r).best)
          fprintf('< %d\t%8.6f\t%8.6f\t%8.6f\t%8.6f\t%8.6f\n', ...
                  d, log(rec.gs(r).l_sigma(d)), log(rec.gs(r).l_boxc(d)), ...
                  rec.gs(r).se(d), ...
                  rec.gs(r).sp(d), ...
                  rec.gs(r).gm(d) );
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
          rec.gs(r+1).precision     = 1/2^(r-1); % as in neighbor function
          rec.gs(r+1).sigma         = logunique( ns, 1e-5 );
          rec.gs(r+1).boxconstraint = logunique( nc, 1e-5 );
      end
      
      rec.numcv = rec.numcv + length(rec.gs(r).sigma)*length(rec.gs(r).boxconstraint);
      rec.time = round(etime(clock,rec.begintime));
      fprintf( '#\n> time\t%02d:%02d\n', floor(rec.time/60), mod(rec.time,60))
    
    end % for r    
    % matlabpool close

    % perform classification on test datasets
    bidx = find(rec.gs(rec.grid_refine).best,1,'first');

    % write tsv-data
    fid = fopen( dlm_outfile, 'a' );
    % fprintf( fid, [ 'id\ttrain/test\tsetup\tdataset\tfeatset\t'...
    %                 'classifier\tparam1\tparam2\tse\tsp\tgm/perf\n' ] ); 
    fprintf( fid, '%f\t%d\t%s\t%s\t%s\t%d\t%s\t%9.8g\t%9.8g\t%9.8g\t%9.8g\t%9.8g\n', ...
                 datenum(rec.begintime), seed, 'train', dataset, 'train', featset, ...
             'svm-rbf', log(rec.gs(rec.grid_refine).l_boxc(bidx)), ...
             log(rec.gs(rec.grid_refine).l_sigma(bidx)), ...
             rec.gs(rec.grid_refine).se(bidx), ...
             rec.gs(rec.grid_refine).sp(bidx), ...
             rec.gs(rec.grid_refine).gm(bidx) );
    
    if max(rec.gs(rec.grid_refine).gm) < 0.75
        fprintf('! train CV rate too low, not testing\n')
        for i=1:length(rec.test)
            fprintf( fid, '%f\t%d\t%s\t%s\t%s\t%d\t%s\t%9.8g\t%9.8g\t%9.8g\t%9.8g\t%9.8g\n', ...
                 datenum(rec.begintime), seed, 'test', dataset, rec.test(i).name, featset, ...
                     'svm-rbf', [], [], [], [], 0 );
        end
        fclose(fid)
        return
    end
    
    fprintf('#\n# begin testing\n');
    fprintf('# \t\tdataset\t\t\tclass\tsize\tperformance\n');
    fprintf('# \t\t-------\t\t\t-----\t----\t-----------\n');

    for i=1:length(rec.test)
        rec.test(i).cls_results = zeros(size(rec.test(i).data,1),rec.num_iterations); 
        rec.test(i).performance = zeros(1,rec.num_iterations); 
        
        for t=1:rec.num_iterations
            model = rec.gs(rec.grid_refine).raw_results{bidx,t,6};
            rec.test(i).cls_results(:,t) = round(svmclassify(model, rec.test(i).data(:,features)));
            rec.test(i).performance(t)     = mean( ...
                rec.test(i).cls_results(:,t) == rec.test(i).class);
        end
        rec.test(i).avg_performance =  mean(rec.test(i).performance);

        fprintf('+ %32s\t%d\t%d\t%8.6f\n',...
                rec.test(i).name, rec.test(i).class, size(rec.test(i).data,1), rec.test(i).avg_performance);

        % fprintf( fid, [ 'id\ttrain/test\tsetup\tdataset\tfeatset\t'...
        %                 'classifier\tparam1\tparam2\tse\tsp\tgm/perf\n' ] ); 
        fprintf( fid, '%f\t%d\t%s\t%s\t%s\t%d\t%s\t%9.8g\t%9.8g\t%9.8g\t%9.8g\t%9.8g\n', ...
                 datenum(rec.begintime), seed, 'test', dataset, rec.test(i).name, featset, ...
                 'svm-rbf', log(rec.gs(rec.grid_refine).l_boxc(bidx)), ...
                 log(rec.gs(rec.grid_refine).l_sigma(bidx)), [], [], ...
                 rec.test(i).avg_performance );

        % clear data for saving space
        rec.test(i).data = [];
    end
    fclose(fid);
    
    for r=1:rec.grid_refine
        rec.gs(r).raw_results(:,:,6) = cell(size(rec.gs(r).raw_results(:,:,6)));
    end
    
    fprintf( ['#\n# saving results to ' './results/svm_rbf-' ...
              datestr(rec.begintime,'yyyy-mm-dd_HH.MM.SS') '.mat\n']);
    save( ['./results/svm_rbf-' datestr(rec.begintime,'yyyy-mm-dd_HH.MM.SS') '.mat'],'-struct', 'rec');

end
