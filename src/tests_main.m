function results = tests_main(case_name, npart, cvratio, seed, classifiers, balanced)
%TESTS_MAIN Pruebas caso CASE_NAME

    if nargin < 2 || isempty(npart), npart = 10; end
    if nargin < 3 || isempty(cvratio), cvratio = 0.1; end
    if nargin < 4 || isempty(seed), seed = 1135; end
    if nargin < 5 || isempty(classifiers)
        classifiers = { ...
            'mlp:trivial', ...
            'mlp:mlp', ...
            'linear:trivial', ...
            'linear:gridsearch', ...
            'linear:empirical', ...
            'rbf:trivial', ...
            'rbf:gridsearch', ...
            'rbf:empirical', ...
            'rbf:rmb' ...
                      };
    end
    if nargin < 6 || isempty(balanced), balanced = false; end

    % Generar problema
    prob = [];
    if balanced,
        prob = problem_gen(case_name,'CVPartitions',npart,'CVRatio',cvratio, 'Balanced', seed);
    else
        prob = problem_gen(case_name,'CVPartitions',npart,'CVRatio',cvratio, seed);
    end

    % Características: incluir triplets en caso xue
    features = [4,5,8];
    if strncmpi(case_name,'xue',3)
        features = [4,5,8,2,3,6];
    end
    if balanced, features = [4,5,8]; end

    % Formato clasificadores y estrategias de sel. modelo
    clsspec_fmt = '^([\w]+):([\w]+)$';

    % Cell array con resultados
    results = cell(numel(features),numel(classifiers));

    for i=1:numel(features)
        for j=1:numel(classifiers)

            % Extraer clasificador y msm
            g = regexp(classifiers{j}, clsspec_fmt, 'tokens');
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


    fprintf('%% ------------------------------------------------------------\n')
    fprintf('%% Problema: %s (Gm), seed %g\n', case_name, seed)
    fprintf('%% ------------------------------------------------------------\n')
    fprintf('Características & ')
    fprintf('& %s ', classifiers{:})
    fprintf('\\\\\n')
    for i=1:numel(features)
        fprintf('%d ', features(i))
        for j=1:numel(classifiers)
            cur = results{i,j};
            fprintf('& %5.1f ', 100*cur.gm )
        end
        fprintf('\\\\\n')
    end
    fprintf('%% ------------------------------------------------------------\n')


    fprintf('%% ------------------------------------------------------------\n')
    fprintf('%% Problema: %s (Se), seed %g\n', case_name, seed)
    fprintf('%% ------------------------------------------------------------\n')
    fprintf('Características & ')
    fprintf('& %s ', classifiers{:})
    fprintf('\\\\\n')
    for i=1:numel(features)
        fprintf('%d ', features(i))
        for j=1:numel(classifiers)
            cur = results{i,j};
            fprintf('& %5.1f ', 100*cur.se )
        end
        fprintf('\\\\\n')
    end
    fprintf('%% ------------------------------------------------------------\n')


    fprintf('%% ------------------------------------------------------------\n')
    fprintf('%% Problema: %s (Sp), seed %g\n', case_name, seed)
    fprintf('%% ------------------------------------------------------------\n')
    fprintf('Características & ')
    fprintf('& %s ', classifiers{:})
    fprintf('\\\\\n')
    for i=1:numel(features)
        fprintf('%d ', features(i))
        for j=1:numel(classifiers)
            cur = results{i,j};
            fprintf('& %5.1f ', 100*cur.sp )
        end
        fprintf('\\\\\n')
    end
    fprintf('%% ------------------------------------------------------------\n')

    fprintf('%% ------------------------------------------------------------\n')
    fprintf('%% Problema: %s (Seg.), seed %g\n', case_name, seed)
    fprintf('%% ------------------------------------------------------------\n')
    fprintf('Características & ')
    fprintf('& %s ', classifiers{:})
    fprintf('\\\\\n')
    for i=1:numel(features)
        fprintf('%d ', features(i))
        for j=1:numel(classifiers)
            cur = results{i,j};
            fprintf('& %5.0f ', cur.time )
        end
        fprintf('\\\\\n')
    end
    fprintf('%% ------------------------------------------------------------\n')

    fprintf('%% ------------------------------------------------------------\n')
    fprintf('%% Problema: %s (N. entrenamientos), seed %g\n', case_name, seed)
    fprintf('%% ------------------------------------------------------------\n')
    fprintf('Características & ')
    fprintf('& %s ', classifiers{:})
    fprintf('\\\\\n')
    for i=1:numel(features)
        fprintf('%d ', features(i))
        for j=1:numel(classifiers)
            cur = results{i,j};
            fprintf('& %5.0f ', cur.nt )
        end
        fprintf('\\\\\n')
    end
    fprintf('%% ------------------------------------------------------------\n')

end
