function results = do_test(test_name, classifier_set, feature_set, randseeds, balanced, mlprepeats)
%DO_TEST Run tests.
%
%  RESULTS = DO_TEST(TEST_NAME, CLASSIFIER_SET, FEATURE_SET, RANDSEEDS,
%                    BALANCED, MLPREPEATS)
%  run tests according to parameters and print result tables.
%  TEST_NAME is a string with a problem name as accepted by SELECT_MODEL.
%  CLASSIFIER_SET is either a string with value 'all' or 'default', or a
%  one-dimensional cell array of strings with 'classifier:strategy' format.
%  the 'default' value equals to { 'mlp:mlp', 'linear:empirical', 'rbf:rmb' };
%  and the 'all' value equals { 'mlp:trivial', 'mlp:mlp', 'linear:trivial', ...
%  'linear:gridsearch', 'linear:empirical', 'rbf:trivial', ...
%  'rbf:gridsearch', 'rbf:empirical','rbf:rmb' };.
%  FEATURE_SET selects the features to test, either an integer vector with
%  feature codes 1..15, or a string with possible values 'all' = [4,5,8] or
%  'xue', meaning [4,5,8,2,3,6].
%
%  Optional arguments are RANDSEEDS, with default value
%  [1135,2236,303456,456789,987654]; BALANCED is a true/false (default=false)
%  flag telling wether to oversample the minority class by repeating elements;
%  and MLPREPEATS which tells the number of (newly-initialized) networks the
%  test should be run on (default 1).
%
%  See also PROBLEM_GEN, SELECT_MODEL.
%

    if nargin < 4 || isempty(randseeds)
        randseeds = [1135,2236,303456,456789,987654];
    end
    if nargin < 5 || isempty(balanced), balanced = false; end
    if nargin < 6 || isempty(mlprepeats), mlprepeats = 1; end

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

                fprintf('test %3.0f/%1.0f: seed %6.0f (%1.0f/%1.0f) featset %1.0f (%1.0f/%1.0f) classifier %s (%1.0f/%1.0f)\n', ...
                        numel(classifiers)*(i-1)+numel(classifiers)*numel(features)*(k-1)+j, ...
                        numel(randseeds)*numel(features)*numel(classifiers), ...
                        randseeds(k), k, numel(randseeds), ...
                        features(i), i, numel(features), ...
                        classifiers{j}, j, numel(classifiers));

                % Extraer clasificador y msm
                g = regexp(classifiers{j}, '^([\w]+):([\w]+)$', 'tokens');
                clstype  = g{1}{1};
                msmethod = g{1}{2};

                % Selección de modelo cronometrada
                time = time_init();
                [model,nt,params] = select_model(prob, features(i), clstype, msmethod, 'MLPNRepeats', mlprepeats);
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
                cur.params = params;

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

    np   = nan(1,nclassif);
    pp   = cell(1,nclassif);
    for k=1:nclassif,
        np(k) = numel(res_all{1}{1,k}.params);
        pp{k} = nan(np(k),nfeats,nseeds);
    end

    for i=1:nseeds
        curs = res_all{i};
        for j=1:nfeats
            for k=1:nclassif
                curr = curs{j,k};
                time(j,k,i) = curr.time;
                se(j,k,i)   = curr.se;
                sp(j,k,i)   = curr.sp;
                gm(j,k,i)   = curr.gm;
                nt(j,k,i)   = curr.nt;
                pp{k}(:,j,i) = curr.params;
            end
        end
    end

    results = struct();
    results.features = features;
    results.classifiers = classifiers;
    results.seeds = randseeds;
    results.raw = res_all;
    results.time = time;
    results.se = se;
    results.sp = sp;
    results.gm = gm;
    results.nt = nt;
    results.pp = pp;

    % -------------------------------------------------------------------------

    feat_names = { 'S-E-T-X', 'T', 'X', 'S', ...
                   'E', 'T-X', 'E-T-X', 'S-E', 'S-T-X', 'S-E-X', ...
                   'E-X', 'S-X', 'E-T', 'S-T', 'S-E-T' };

    m_gm = mean(gm,3); s_gm = std(gm,0,3);
    m_se = mean(se,3); s_se = std(se,0,3);
    m_sp = mean(sp,3); s_sp = std(sp,0,3);

    isnan_gm = all(isnan(m_gm),1);
    isnan_se = all(isnan(m_se),1);
    isnan_sp = all(isnan(m_sp),1);

    w_mcol = 3-isnan_gm-isnan_se-isnan_sp;

    % print classification performance table

    fprintf('\\begin{tabular}{ccr')
    for i=1:nclassif,
        for j=1:w_mcol(i), fprintf('S'), end
        if i<nclassif, fprintf('c'), end
    end
    fprintf('}\n\\toprule\n');
    fprintf('\\mrow{2}{*}{Problema} & \\mrow{2}{*}{Caracts.} & &\n')
    for i=1:nclassif, fprintf('\\mcol{%.0f}{c}{%s}', w_mcol(i), classifiers{i});
        if i<nclassif, fprintf(' &&\n'), else fprintf('\n\\\\\n'), end, end
    for i=1:nclassif, fprintf('\\cmidrule(lr){%.0f-%.0f}', ...
                              4*(i-1)+4, 4*(i-1)+6), end
    fprintf('\n&& ')
    for i=1:nclassif,
        if ~isnan_se(i), fprintf(' & \\ti{SE\\%%}'), end
        if ~isnan_sp(i), fprintf(' & \\ti{SP\\%%}'), end
        if ~isnan_gm(i), fprintf(' & \\ti{Gm\\%%}'), end
        if i<nclassif, fprintf(' &\n'), else fprintf('\n\\\\\n'), end, end
    fprintf('\\midrule\n\\mrow{%.0f}{*}{%s}\n', 2*nfeats, test_name)

    for i=1:nfeats
        fprintf('\\rowMEAN{%3s} ', feat_names{features(i)}')
        for j=1:nclassif
            if ~isnan_se(j), fprintf('& %5.1f ', 100*m_se(i,j)), end
            if ~isnan_sp(j), fprintf('& %5.1f ', 100*m_sp(i,j)), end
            if ~isnan_gm(j), fprintf('& %5.1f ', 100*m_gm(i,j)), end
            if j<nclassif, fprintf('&'), end
        end
        fprintf('\\\\\n')
        fprintf('\\rowSTD       ')
        for j=1:nclassif
            if ~isnan_se(j), fprintf('& %5.1f ', 100*s_se(i,j)), end
            if ~isnan_sp(j), fprintf('& %5.1f ', 100*s_sp(i,j)), end
            if ~isnan_gm(j), fprintf('& %5.1f ', 100*s_gm(i,j)), end
            if j<nclassif, fprintf('&'), end
        end
        fprintf('\\\\')
        if i<nfeats, fprintf('\\rowSKIP'), end
        fprintf('\n')
    end
    fprintf('\\bottomrule\n\\\\\n\\end{tabular}\n')

    m_time = mean(time,3); s_time = std(time,0,3);
    m_nt = mean(nt,3); s_nt = std(nt,0,3);

    % non-trivial classifiers
    ntc=find(cellfun(@(x) isempty(strfind(x,'trivial')),classifiers));
    nntc=numel(ntc);
    nc=numel(classifiers);

    % Print computational cost table

    fprintf('\\begin{tabular}{ccr')
    for i=1:nc, fprintf('SS'), if i<nc, fprintf('c'), end, end
    fprintf('}\n\\toprule\n');
    fprintf('\\mrow{2}{*}{Problema} & \\mrow{2}{*}{Caracts.} & &\n')
    for i=1:nc, fprintf('\\mcol{3}{c}{%s}',classifiers{i})
        if i<nc, fprintf(' &&\n'), else fprintf('\n\\\\\n'), end, end
    for i=1:nc, fprintf('\\cmidrule(lr){%.0f-%.0f}', ...
                              3*(i-1)+4, 3*(i-1)+5), end
    fprintf('\n&&& ')
    for i=1:nc, fprintf('\\ti{$t$} & \\ti{$N$}')
        if i<nc, fprintf(' &&\n'), else fprintf('\n\\\\\n'), end, end
    fprintf('\\midrule\n\\mrow{%.0f}{*}{%s}\n', nfeats, test_name)

    for i=1:numel(features)
        fprintf('\\rowMEAN{%3s} ', feat_names{features(i)}')
        for j=1:nc
            fprintf('& %5.0f & %5.0f ', m_time(i,j), m_nt(i,j))
        end
        fprintf('\\\\\n')
    end
    fprintf('\\bottomrule\n\\\\\n\\end{tabular}\n')

    % print model parameters

    m_pp = cell(1,nclassif);
    s_pp = cell(1,nclassif);
    for k=1:nclassif,
        m_pp{k} = mean(pp{k},3);
        s_pp{k} = std(pp{k},0,3);
    end

    fprintf('\\begin{tabular}{ccr')
    for i=1:nc, for j=1:np(i), fprintf('S'), end, if i<nc, fprintf('c'), end, end
    fprintf('}\n\\toprule\n');
    fprintf('\\mrow{2}{*}{Problema} & \\mrow{2}{*}{Caracts.} & &\n')
    for i=1:nc, fprintf('\\mcol{%.0f}{c}{%s}',np(i), classifiers{i})
        if i<nc, fprintf(' &&\n'), else fprintf('\n\\\\\n'), end, end
    for i=1:nc, fprintf('\\cmidrule(lr){%.0f-%.0f}', ...
                              3*(i-1)+4, 3*(i-1)+5), end
    fprintf('\n&& ')
    for i=1:nc, for j=1:np(i), fprintf(' & p%.0f',j),end
        if i<nc, fprintf(' &\n'), else fprintf('\n\\\\\n'), end, end
    fprintf('\\midrule\n\\mrow{%.0f}{*}{%s}\n', nfeats, test_name)

    for i=1:numel(features)
        fprintf('& \\mrow{2}{*}{%3s} & ', feat_names{features(i)}')
        for j=1:nc
            for k=1:np(j)
                fprintf('& %4.1f ', m_pp{j}(k,i))
            end
            if j<nc, fprintf('&'), end
        end
        fprintf('\\\\\n')
        fprintf('& & ')
        for j=1:nc
            for k=1:np(j)
                fprintf('& %4.1f ', s_pp{j}(k,i))
            end
            if j<nc, fprintf('&'), end
        end
        fprintf('\\\\\n')
    end
    fprintf('\\bottomrule\n\\\\\n\\end{tabular}\n')

end
