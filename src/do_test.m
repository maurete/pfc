function results = do_test(test_name, classifier_set, feature_set, randseeds, balanced)

    if nargin < 4 || isempty(randseeds)
        randseeds = [1135,2236,303456,456789,987654];
    end
    if nargin < 5 || isempty(balanced), balanced = false; end

    classifiers = { 'mlp:mlp', 'linear:empirical', 'rbf:rmb' };
    if isstr(classifier_set)
        if strcmpi(classifier_set, 'all')
            classifiers = { ...
                'mlp:trivial', 'mlp:mlp', ...
                'linear:trivial', 'linear:gridsearch', 'linear:empirical', ...
                'rbf:trivial', 'rbf:gridsearch', 'rbf:empirical','rbf:rmb' ...
                          };
        elseif ~strcmpi(classifier_set,'default')
            error('unknown classifier set requested')
        end
    elseif iscell(classifier_set)
        classifiers = classifier_set;
    else
        error('invalid type for classifier_set')
    end

    features = 8;
    if isstr(feature_set)
        if strcmpi(feature_set, 'xue')
            features = [4,5,8,2,3,6];
        elseif strcmpi(feature_set, 'all')
            features = [4,5,8];
        elseif ~strcmpi(feature_set,'default')
            error('unknown feature set requested')
        end
    elseif isnumeric(feature_set)
        features = feature_set;
    else
        error('invalid type for feature_set')
    end

    balanced_str = '';
    if balanced, balanced_str = 'Balanced'; end

    npart = 10;
    cvratio = 1/npart;

    nfeats   = numel(features);
    nclassif = numel(classifiers);
    nseeds   = numel(randseeds);

    res_all = cell(1,numel(randseeds));

    % Random seed loop
    for k=1:numel(randseeds)

        prob = problem_gen(test_name, 'CVPartitions', npart, ...
                           'CVRatio', cvratio, balanced_str, randseeds(k));

        % Cell array con resultados
        results = cell(numel(features),numel(classifiers));

        for i=1:numel(features)
            for j=1:numel(classifiers)

                % Extraer clasificador y msm
                g = regexp(classifiers{j}, '^([\w]+):([\w]+)$', 'tokens');
                clstype  = g{1}{1};
                msmethod = g{1}{2};

                % Selección de modelo cronometrada
                time = time_init();
                [model,nt] = select_model(prob, features(i), clstype, msmethod);
                time = time_tick(time,1);

                % Clasificar el problema
                res = problem_classify(prob,model);

                % Guardar informacion
                cur = struct();
                cur.featureset = features(i);
                cur.classifier = clstype;
                cur.strategy = msmethod;
                cur.time = time.time;
                cur.se = res(1).se;
                cur.sp = res(1).sp;
                cur.gm = res(1).gm;
                cur.nt = nt;

                results{i,j} = cur;
            end
        end
        res_all{k} = results;
    end

    time = nan(nfeats,nclassif,nseeds);
    se   = nan(nfeats,nclassif,nseeds);
    sp   = nan(nfeats,nclassif,nseeds);
    gm   = nan(nfeats,nclassif,nseeds);
    nt   = nan(nfeats,nclassif,nseeds);

    for i=1:nseeds
        curs = res_all{i}
        for j=1:nfeats
            for k=1:nclassif
                curr = curs{j,k}
                time(j,k,i) = curr.time;
                se(j,k,i)   = curr.se;
                sp(j,k,i)   = curr.sp;
                gm(j,k,i)   = curr.gm;
                nt(j,k,i)   = curr.nt;
            end
        end
    end

    results = struct();
    results.features = features;
    results.classifiers = classifiers;
    results.seeds = randseeds;
    rsults.raw = res_all;
    results.time = time;
    results.se = se;
    results.sp = sp;
    results.gm = gm;
    results.nt = nt;


    fprintf('%% ------------------------------------------------------------\n')
    fprintf('%% Problema: %s\n', test_name)
    fprintf('%% ------------------------------------------------------------\n')
    fprintf('& %s & ', 'caract')
    fprintf('& %s -SE & -SP & -Gm ', classifiers{:})
    fprintf('\\\\\n')

    m_gm = mean(gm,3); s_gm = std(gm,0,3);
    m_se = mean(se,3); s_se = std(se,0,3);
    m_sp = mean(sp,3); s_sp = std(sp,0,3);

    for i=1:numel(features)
        fprintf(' & %d & %5s ', features(i), 'mean')
        for j=1:numel(classifiers)
            fprintf('& %5.1f & %5.1f & %5.1f ', 100*m_se(i,j), 100*m_sp(i,j), 100*m_gm(i,j))
        end
        fprintf('\\\\\n')
        fprintf(' & %d & %5s ', features(i), 'std')
        for j=1:numel(classifiers)
            fprintf('& %5.1f & %5.1f & %5.1f ', 100*s_se(i,j), 100*s_sp(i,j), 100*s_gm(i,j))
        end
        fprintf('\\\\\n')
    end
    fprintf('%% ------------------------------------------------------------\n')

    fprintf('%% ------------------------------------------------------------\n')
    fprintf('%% Problema: %s (cost)\n', test_name)
    fprintf('%% ------------------------------------------------------------\n')
    fprintf('& %s & ', 'caract')
    fprintf('& %s -time & -n_trainings ', classifiers{:})
    fprintf('\\\\\n')

    m_time = mean(time,3); s_time = std(time,0,3);
    m_nt = mean(nt,3); s_nt = std(nt,0,3);

    for i=1:numel(features)
        fprintf(' & %d & %5s ', features(i), 'mean')
        for j=1:numel(classifiers)
            fprintf('& %5.0f & %5.0f ', m_time(i,j), m_nt(i,j))
        end
        fprintf('\\\\\n')
        fprintf(' & %d & %5s ', features(i), 'std')
        for j=1:numel(classifiers)
            fprintf('& %5.0f & %5.0f ', s_time(i,j), s_nt(i,j))
        end
        fprintf('\\\\\n')
    end
    fprintf('%% ------------------------------------------------------------\n')

end
