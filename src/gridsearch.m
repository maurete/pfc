function gridsearch ( dataset, featset, kernel, randseed )
    
    if nargin < 4, randseed = [303456; 456789; 5829]; end
    
    % aux functions
    pick      = @(x,n) x(randsample(size(x,1),min(size(x,1),n)),:);
    shuffle   = @(x)   x(randsample(size(x,1),size(x,1)),:);
    stpick    = @(i,x,n) x(strandsample(random_seeds(i),size(x,1),min(size(x,1),n)),:);
    stshuffle = @(i,x)   x(strandsample(random_seeds(i),size(x,1),size(x,1)),:);

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
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Global variables

    % number of random seeds
    Nrs = length(randseed);
    
    % number of partitions
    Np = 5;
    
    % number of grid refinements
    Ngr = 4;
    
    % find if rbf kernel is selected
    rbf = false;
    if strncmpi(kernel,'rbf',3); rbf = true;
    else assert(strncmpi(kernel,'lin',3), ...
        'Fatal error: unknown kernel function specified.');
    end
    
    % initial parameters
    sig0 = 0;
    if rbf; sig0 = [-15:2:15]; end
    box0 = [-4:2:14];
    
    % initial grid
    grid = zeros(length(sig0),length(box0),3);
    % boxconstraint C
    grid(:,:,2) = ones(length(sig0),length(box0))*diag(box0);
    % rbf parameter sigma
    grid(:,:,3) = diag(sig0)*ones(length(sig0),length(box0));
        
    %%% Load data %%%
    
    data = struct();
    for i=1:Nrs
        [ data(i).train data(i).test] = load_data( dataset, randseed(i));
        % generate CV partitions
        [data(i).tr_real data(i).cv_real] = ...
            stpart(randseed(i), data(i).train.real, Np);
        [data(i).tr_pseudo data(i).cv_pseudo] = ...
            stpart(randseed(i), data(i).train.pseudo, Np);
    end
    
    %%% timing and output %%%
    
    begintime = clock;
    time = 0;
    % number of experiments
    Nexp = 0;
        
    % file where to save tabulated train/test data
    tabfile = 'resultsv2.tsv';
    
    % write file header if not exists
    if ~exist( tabfile )
        fid = fopen( tabfile, 'a' );
        fprintf( fid, [ '#dsetup\tclass\tdataset\tfeatset\t' ...
                        'classifier\tparam1\tparam2\tP\n' ] ); 
        fclose(fid);
    end
    
    % helper function for writing to file
    function writetab(fid,cls,dset,param1,param2,result)
        fprintf(fid, '%s\t%d\t%s\t%d\tsvm-%s\t%9.8g\t%9.8g\t%9.8g\n', ...
                dataset, cls, dset, featset, kernel, param1, param2, result );
    end
        
    % fprintf('#\n> begin svm-%s\n#\n', classifier);
    % fprintf('> dataset\t%s\n', dataset );
    % fprintf('> featureset\t%s\n', fname{featset} );
    % fprintf([ '# begin cross-validation training\n> partitions\t%d\n#\n', ...
    %           '# dataset\tsize\t#train\t#test\n', ...
    %           '# -------\t----\t------\t-----\n', ...
    %           '> real\t\t%d\t%d\t%d\n', ...
    %           '> pseudo\t%d\t%d\t%d\n#\n' ], ...
    %         S.partitions, ...
    %         size(S.data(1).train.real,     1), ...
    %         size(S.data(1).cv_train_real,  1), ...
    %         size(S.data(1).cv_test_real,   1), ...
    %         size(S.data(1).train.pseudo,   1), ...
    %         size(S.data(1).cv_train_pseudo,1), ...
    %         size(S.data(1).cv_test_pseudo, 1));
    
    %%% create matlab pool %%%
    Nworkers = 12;
    if matlabpool('size') == 0
        while( Nworkers > 1 )
            try
                matlabpool(Nworkers);
                break
            catch e
                Nworkers = Nworkers-1;
                fprintf(['# trying %d workers\n'], Nworkers);
            end
        end
    end
    fprintf('# using %d matlabpool workers\n', matlabpool('size'));

    %%% grid-search %%%
    
    % percent best values to try
    thr = 0.9;

    % mark all values as never tested
    tested = zeros(size(grid(:,:,1)));
    masked = zeros(size(grid(:,:,1)));
    
    for g = 1:Ngr

        p_sig = grid(:,:,3);
        p_box = grid(:,:,2);

        g_res = grid(:,:,1);
        g_res( find(1-[tested|masked]) ) = 0;

        for s = 1:Nrs

            for p = 1:Np
               
                % partition
                
                train = shuffle( [data(s).train.real(  data(s).tr_real(  :,p),:); ...
                                  data(s).train.pseudo(data(s).tr_pseudo(:,p),:)] );
                
                test_real   = data(s).train.real(  data(s).cv_real(  :,p),:);
                test_pseudo = data(s).train.pseudo(data(s).cv_pseudo(:,p),:);

                % parfor auxilliaries
                pf_idx = find(1-[floor(tested) | masked])';                
                pf_res = zeros(size(pf_idx));
                pf_tst = zeros(size(pf_idx));
                pf_msk = zeros(size(pf_idx));
                %        fprintf('trying %d parameters seed %d part %d ...\n', length(pf_idx),randseed(s),p)
                parfor k = 1:length(pf_idx)
                    n = pf_idx(k);
                    Gm = 0;
                    try
                        model = struct();
                        
                        if rbf
                            model = svmtrain(train(:,features),train(:,67), ...
                                         'Kernel_Function','rbf', ...
                                         'rbf_sigma',pow2(p_sig(n)), ...
                                         'boxconstraint',pow2(p_box(n)));
                        else
                            model = svmtrain(train(:,features),train(:,67), ...
                                         'Kernel_Function','linear', ...
                                         'boxconstraint',pow2(p_box(n)));
                        end
                        
                        res_r = round(svmclassify(model, test_real(:,features)));
                        res_p = round(svmclassify(model, test_pseudo(:,features)));
                      
                        Se = mean( res_r == 1 );
                        Sp = mean( res_p == -1 );
                        Gm = geomean( [Se Sp] )

                        % % ignore this paramset if it's too bad
                        % if Gm < 0.70
                        %     ignore(n) = 1;
                        %     continue
                        % end

                        % save Gm to results array
                        pf_res(k) = Gm/(Np*Nrs);
                        pf_tst(k) = pf_tst(k)+1/(Np*Nrs);
                    catch e
                        % ignore this paramset if it does not converge
                        if strfind(e.identifier,'NoConvergence')
                            pf_tst(k) = 1;
                            pf_msk(k) = 1;
                            pf_res(k) = 0;
                        elseif strfind(e.identifier,'InvalidInput')
                            pf_tst(k) = 1;
                            pf_msk(k) = 1;
                            pf_res(k) = 0;
                        else
                            fprintf('! %s / %s', e.identifier, e.message)
                        end
                    end % try
                    
                end % parfor k

                tested(pf_idx) = pf_tst;
                masked(pf_idx) = pf_msk;
                
                % @TODO fix need to transpose pf_res when using linear kernel
                if rbf
                    g_res(pf_idx) = g_res(pf_idx) + pf_res;
                else
                    g_res(pf_idx) = g_res(pf_idx) + pf_res';
                end
                
            end % parfor p
            
        end % parfor s
        
        % save average partition-randseed into the grid
        grid(:,:,1) = g_res;
        
        % if not on last iteration
        if g < Ngr
            % interpolate grid
            [grid aux] = gridinterp(grid);
            % mark already tested values
            tested = [gridinterp(tested) & 1-aux]*1;            
        end      

        % mask worst values to avoid testing
        aux = grid(:,:,1);
        [zz idx]  = sort(aux(1:numel(aux)));
        masked = zeros(size(aux));
        masked(idx(1:round(thr*numel(aux)))) = 1;
        
        % also mask non-absolute best results
        masked = masked | [ abs( aux-max(max(aux)) ) > 2/4^(g+2) ];

        [ii jj] = ind2sub(size(aux),find(aux==max(max(aux)),1,'first'));
        fprintf('# found best params: C = %5.2f, sig = %5.2f with Gm = %5.2f %%.\n',...
                grid(ii,jj,2), grid(ii,jj,3),100*grid(ii,jj,1))
        
        if g < Ngr
            if sum(sum([masked|tested]*1)) == prod(size(masked))
                fprintf(['\n# aborting grid search at precision %8.4f, ' ...
                         'convergence reached:\n'], 1/g)
                fprintf('- break criteria: no new params with Gm = +-%5.4f.\n\n', ...
                        2/4^(g+2))
                break
            end
            fprintf('# %5d new params for next iteration with Gm = +-%5.4f.\n',...
                    sum(sum(1-[masked|tested])), 2/4^(g+2))
        end
    end

    %%% test best-performing parameters %%%
    
    r_gm =  grid(:,:,1);
    p_sig = grid(:,:,3);
    p_box = grid(:,:,2);
    
    b_idx = find(r_gm==max(max(r_gm)),1,'first');
    fprintf('# best crossval sig %5.2f boxconstraint %5.2f gm %5.2f %%\n',...
            p_sig(b_idx),p_box(b_idx),100*r_gm(b_idx))

    Ntest = length(data(1).test);
    t_res = zeros(Ntest,1);
    for s=1:Nrs
        train = shuffle( [data(s).train.real; ...
                          data(s).train.pseudo] );
        model = struct();
        if rbf
            model = svmtrain(train(:,features),train(:,67), ...
                             'Kernel_Function','rbf', ...
                             'rbf_sigma',pow2(p_sig(b_idx)), ...
                             'boxconstraint',pow2(p_box(b_idx)));
        else
            model = svmtrain(train(:,features),train(:,67), ...
                             'Kernel_Function','linear', ...
                             'boxconstraint',pow2(p_box(b_idx)));
        end
        
        for i=1:Ntest
            cls_results = round(svmclassify(model, data(s).test(i).data(:,features)));
            t_res(i)  = t_res(i)+(mean( cls_results == data(s).test(i).class))/Nrs;
        end
        
    end % for rs

    % print and write test results
    fprintf('# \t\tdataset\t\t\tclass\tsize\tperformance\n');
    fprintf('# \t\t-------\t\t\t-----\t----\t-----------\n');
    %fid = fopen( tabfile, 'a' );
    for i=1:Ntest
        fprintf('+ %32s\t%d\t%d\t%5.2f %%\n',...
                data(1).test(i).name, data(1).test(i).class, ...
                size(data(1).test(i).data,1), 100*t_res(i));
        
        % writetab(fid, S.data(1).test(i).class, S.data(1).test(i).name, ...
        %          log(S.GS(S.gridsearch).bestZ(1)), ...
        %          log(S.GS(S.gridsearch).bestC(1)), mean(S.test(i,:)))
    end

end
    
    
    
    
    
    
    
    
    
 
    % % perform classification on test datasets
    % bidx = find(S.GS(S.gridsearch).best,1,'first');

    % % write tsv-data
    % fid = fopen( tabfile, 'a' );
    % writetab(fid, 0, 'train', log(S.GS(S.gridsearch).l_sigma(bidx)), ...
    %          log(S.GS(S.gridsearch).l_boxc(bidx)), ...
    %          S.GS(S.gridsearch).gm(bidx))    
    % if max(S.GS(S.gridsearch).gm) < 0.75
    %     fprintf('! train CV rate too low, not testing\n')
    %     for i=1:length(S.data(1).test)
    %         writetab(fid, S.data(1).test(i).class, S.data(1).test(i).name,[],[],0)
    %     end
    %     fclose(fid);
    %     return
    % end
              
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % fprintf('#\n# begin testing: Z=%g, C=%g\n', ...
    %         log(S.GS(S.gridsearch).bestZ(1)), ...
    %         log(S.GS(S.gridsearch).bestC(1)));
    % S.test = zeros(length(S.data(rs).test), length(S.random_seeds));

    % for rs=1:length(S.random_seeds)
        
    %     train_real        = S.data(rs).train.real;
    %     train_pseudo      = S.data(rs).train.pseudo;
    %     % part_train_real   = S.data(rs).cv_train_real;
    %     % part_train_pseudo = S.data(rs).cv_train_pseudo;
    %     % part_test_real    = S.data(rs).cv_test_real;
    %     % part_test_pseudo  = S.data(rs).cv_test_pseudo;
        
    %     R = S.gridsearch;

    %     train = stshuffle(rs,[train_real;train_pseudo]);
        
    %     train_lbls = train(:,67);
    %     % train      = train(:,1:66);
        
    %     model = svmtrain(train(:,features),train_lbls, ...
    %                      'Kernel_Function','rbf', ...
    %                      'rbf_sigma',S.GS(R).bestZ(1), ...
    %                      'boxconstraint',S.GS(R).bestC(1));

    %     for i=1:length(S.data(rs).test)
    %         cls_results = round(svmclassify(model, S.data(rs).test(i).data(:,features)));
    %         S.test(i,rs) = mean( cls_results == S.data(rs).test(i).class);
    %     end
        
    % end % for rs
    
    % % print and write test results
    % fprintf('# \t\tdataset\t\t\tclass\tsize\tperformance\n');
    % fprintf('# \t\t-------\t\t\t-----\t----\t-----------\n');
    % fid = fopen( tabfile, 'a' );
    % for i=1:length(S.data(1).test)
    %     fprintf('+ %32s\t%d\t%d\t%8.6f\n',...
    %             S.data(1).test(i).name, S.data(1).test(i).class, ...
    %             size(S.data(1).test(i).data,1), mean(S.test(i,:)));
        
    %     writetab(fid, S.data(1).test(i).class, S.data(1).test(i).name, ...
    %              log(S.GS(S.gridsearch).bestZ(1)), ...
    %              log(S.GS(S.gridsearch).bestC(1)), mean(S.test(i,:)))
    % end
    % fclose(fid);
