function svm_own_libsvm ( num_iterations )

    if nargin < 1
        num_iterations = 10
    end
    pick = @(x,n) x(randsample(size(x,1),min(size(x,1),n)),:);
    shuffle = @(x) x(randsample(size(x,1),size(x,1)),:);

    addpath('/home/mauro/code/libsvm-3.12/matlab/');
    which('svmtrain')


    % load train datasets
    real = loadset('mirbase20-nr','all', 0);
    pseudo1 = loadset('coding','all', 1);
    pseudo2 = loadset('other-ncrna','all', 2);
    pseudo3 = loadset('functional-ncrna','all', 3);
    pseudo = [ pseudo1; pseudo2; pseudo3 ];

    num_workers = 12;
    if matlabpool('size') == 0
        while( num_workers > 1 )
            try
                matlabpool(num_workers);
                break
            catch e
                num_workers = num_workers-1;
                fprintf(['too many workers, trying with %d..\n'], num_workers);
            end
        end
    end

    % initial sigma-boxconstraint values
    sigma = exp([-15:2:15]');
    boxconstraint = exp([-5:15]);
    sigma = exp([0:10]');
    boxconstraint = exp([0:10]);
    best = 0;

    % refine sigma-bc
    for r=1:4

      % avoid nested loops linearizing Z-C matrix
      l_sigma = reshape( diag(sigma)*ones(length(sigma),length(boxconstraint)), 1, []);
      l_boxc  = reshape( ones(length(sigma),length(boxconstraint))*diag(boxconstraint), 1, []);

      se = zeros( num_iterations, length(l_boxc) ); % sensitivity
      sp = zeros( num_iterations, length(l_boxc) ); % specificity

      % SVM training and crossval
      [tr_real ts_real]     = partset(real, 11103);
      [tr_pseudo ts_pseudo] = partset(pseudo,9588);

      if r == 1
          fprintf('REAL %d PSEUDO %d TR+ %d TR- %d TE+ %d TE- %d\n', ...
                  size(real,1), size(pseudo,1), size(tr_real,1), ...
                  size(tr_pseudo,1), size(ts_real,1), size(ts_pseudo, 1))
      end

      ignore = zeros(size(l_sigma));

      ir = 1;
      ip = 1;
      for t=1:num_iterations
	  if ir > size(tr_real,2)
              [tr_real ts_real] = partset(real,11103); ir=1;
	  end
	  if ip > size(tr_pseudo,2)
              [tr_pseudo ts_pseudo] = partset(pseudo,9588); ip=1;
	  end

          train_data = shuffle( [  real(  tr_real(:,ir),1:67); ...
                                 pseudo(tr_pseudo(:,ip),1:67)] );
          train_lbls = train_data(:,67);
          [train_data f s] = scale_data(train_data(:,1:66));

          test_real   = scale_data(  real(  ts_real(:,ir),1:66),f,s);
          test_pseudo = scale_data(pseudo(ts_pseudo(:,ip),1:66),f,s);

          if t==1
              beg = clock;
              model = svmtrain(double(train_lbls), double(train_data), ...
                               sprintf('-g %8.6f -c %8.6f', ...
                                       l_sigma(1), l_boxc(1)));
              elap = round(etime(clock,beg));
              fprintf( 'time needed for each training: %02d:%02d.\n', floor(elap/60), ...
                       mod(elap,60))
          end

          parfor n=1:length(l_sigma)
              fprintf('%d/%d ', n, length(l_sigma))
              if ignore(n) continue; end
              try

                  model = svmtrain(double(train_lbls), double(train_data), ...
                                   sprintf('-g %8.6f -c %8.6f', ...
                                   l_sigma(n), l_boxc(n)));

                  [res_r ign ign] = svmpredict(double(rand(size(test_real,1))), double(test_real), model);
                  [res_p ign ign] = svmpredict(double(rand(size(test_pseudo,1))), double(test_pseudo), model);

                  res_r = round(res_r);
                  res_p = round(res_p);

                  se(t,n) = mean( res_r == 1 );
                  sp(t,n) = mean( res_p == -1 );

                  if geomean( [se(t,n) sp(t,n)] ) < 0.3
                      ignore(n) = 1;
                  end

              catch e
                  e
              end
          end
      end

      gm = reshape(geomean([mean(se,1);mean(sp,1)],1),length(sigma),[]);
      se = reshape(mean(se,1),length(sigma),[]);
      sp = reshape(mean(sp,1),length(sigma),[]);

      best = max(max(gm));
      [bz, bc] = find(best-gm==0,1,'first');

      fprintf('Step %d best: SE %8.6f SP %8.6f GM %8.6f for Z,C %8.6f %8.6f\n', ...
              r, se(bz,bc), sp(bz,bc), gm(bz,bc), sigma(bz), ...
              boxconstraint(bc));

      sigma = exp([log(sigma(bz))-4/r:1/r:log(sigma(bz))+4/r])';
      boxconstraint = exp([log(boxconstraint(bc))-4/r:1/r:log(boxconstraint(bc))+4/r]);

    end
    matlabpool close
end