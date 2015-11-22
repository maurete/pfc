function out = webif (classifier, featureset, method, positives, negatives, pre_trained_model, test_set, test_set_class )

    % load jsonlab for data import/export
    addpath('./jsonlab');

    % try creating a working directory
    work_dir = './run';
    if ~isdir(work_dir)
        if ~mkdir(work_dir)
            % fall back to current directory
            work_dir = '.';
        end
    end

    % create unique identifier for this job
    job_id = sprintf('%015d',floor(now*1e6));
    while exist(fullfile(work_dir,[job_id,'.log'])) ~= 0
        pause on;
        pause(1);
        pause off;
        job_id = sprintf('%015d',floor(now*1e6));
    end

    % set out to temporary output file
    logfile  = fullfile(work_dir,[job_id,'.log']);
    jsonfile = fullfile(work_dir,[job_id,'.json']);
    htmlfile = fullfile(work_dir,[job_id,'.html']);
    out = logfile;

    % write output to log file
    lh = fopen(logfile, 'w');
    info = @(str,varargin) fprintf( ...
        lh, [strrep(str,'"','\"'),'\n'], varargin{:});

    % execution variables
    do_train = false;
    do_test = false;
    trainproblem = [];
    trainmodel = [];
    testproblem = [];
    testresults = [];

    try
    % print friendly warning for user
    info('* ---------------------------------------------------------------');
    info('* PLEASE NOTE: If you only see this instead of an HTML report,');
    info('* program execution ended prematurely. This probably indicates');
    info('* either an error in processing supplied data, or a program bug.');
    info('* ---------------------------------------------------------------');
    info('');

    % normalize input variables
    info('* Normalizing input variables....');
    if strfind(lower(classifier),'mlp'), classifier = 'mlp';    end
    if strfind(lower(classifier),'lin'), classifier = 'linear'; end
    if strfind(lower(classifier),'rbf'), classifier = 'rbf';    end

    if     strfind(lower(method),'rmb'), method = 'rmb';
    elseif strfind(lower(method),'emp'), method = 'empirical';
    elseif strfind(lower(method),'gri'), method = 'gridsearch';
    elseif strfind(lower(method),'tri'), method = 'trivial';
    else,                                method = '';
    end

    if strfind(lower(featureset),'str'), features = '5';
        if strfind(lower(featureset),'seq'), features = '8'; end
    else, features = '4';
    end

    if ~isstr(test_set_class)
        test_set_class = sprintf('%g',test_set_class);
    end

    info('* Classifier: %s', classifier);
    info('* Model selection method: %s', method);
    info('* feature set id: %s', featureset);

    if exist(pre_trained_model) == 2
        info('* Pre-trained model supplied. Not doing model selection.');

        fid = fopen(pre_trained_model);
        if fid < 0
            info('* Can''t open supplied model file. Aborting now!');
            return
        end

        info('* Begin parsing model file...');
        jsondata = {};
        jsonflag = 0;
        lc = 0;
        while ~feof(fid)
            l = fgetl(fid);
            if strfind(l,'>>> BEGIN JSON FORMATTED DATA >>>')
                jsonflag=1;
                continue;
            end
            if strfind(l,'<<< END JSON FORMATTED DATA <<<')
                jsonflag=0;
                break;
            end
            if jsonflag
                lc = lc+1;
                jsondata{lc} = l;
            end
        end
        fclose(fid);

        jsondata = sprintf('%s\n',jsondata{:});
        data = [];
        try
            data = loadjson(jsondata);
            info('* Model file successfully read.');
        catch e
            try
                data = loadjson(pre_trained_model);
                info('* Model file successfully read (alternate).');
            catch e
                info('* Error reading model file, giving up.');
                return
            end
        end

        trainproblem = data.trainproblem;
        model = data.model;
        trainmodel = model;
        if isstr(trainmodel)
            trainmodel = readstr(model);
            info('* Converted string-encoded model into Matlab data.');
        end

        % print some info about model and problem
        info(evalc('trainmodel'));
        info(evalc('trainproblem'));

    else
        do_train = true;
        info('* Creating training problem..');

        % create training problem
        info([ '>> problem = problem_gen({''', positives, ...
               ''',1,1,''', negatives, ''',-1,1})' ]);
        [output, trainproblem] = evalc( ...
            ['problem_gen({''', positives,''',1,1,''',negatives,''',-1,1})']);
        info(output);
        info(evalc('trainproblem'));

        info('* Performing model selection..');
        % perform model selection / training
        info([ '>> trainmodel = select_model(trainproblem,', features, ...
               ',''', classifier, ''',''', method, ''')' ]);
        [output, trainmodel] = evalc([ 'select_model(trainproblem,', features, ...
                            ',''', classifier, ''',''', method, ''')' ]);
        info(output);
        model = trainmodel;
        info(evalc('trainmodel'));

        % if model is an neural network, serialize it
        if strfind(classifier,'mlp')
            model = savestr(trainmodel);
            info('* MLP trained model successfully serialized.');
        end

    end

    % Check both training problem and model have been read/generated
    if (isempty(trainproblem) || isempty(trainmodel))
        info('* Unexpected empty train problem and/or model (ERROR!)');
    end

    if exist(test_set) == 2
        do_test = true;
        info('* Testing');

        info(['>> testproblem = problem_gen({''', ...
              test_set,''',',test_set_class,',0,},trainproblem)']);
        [output, testproblem] = evalc( ['problem_gen({''', test_set, ...
                            ''',',test_set_class,',0,},trainproblem)'] );
        info(output);
        info(evalc('testproblem'));

        info(['>> testresults = problem_classify(testproblem,trainmodel)']);
        [output, testresults] = evalc( ...
            'problem_classify(testproblem,trainmodel)');
        info(output);
    end

    % dump problem and model into json structures
    jsondata_trainproblem = savejson('',trainproblem);
    info('* Successful conversion of train problem data into json string');
    jsondata_trainmodel = savejson('',model);
    info('* Successful conversion of model data into json string');

    jsondata_testproblem = savejson('',testproblem);
    info('* Successful conversion of test problem data into json string');
    jsondata_testresults = savejson('',testresults);
    info('* Successful conversion of test results into json string');

    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % JSON data file generation
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    info('* Writing JSON data file..');
    jh = fopen(jsonfile, 'w');
    fprintf(jh,'{');

    % write problem json
    fprintf(jh,'\n"trainproblem":\n');
    fprintf(jh,'%s',jsondata_trainproblem);

    % write model json
    fprintf(jh,',\n"model":\n');
    fprintf(jh,'%s',jsondata_trainmodel);

    fprintf(jh,',\n"testproblem":\n');
    fprintf(jh,'%s',jsondata_testproblem);

    % write model json
    fprintf(jh,',\n"testresults":\n');
    fprintf(jh,'%s',jsondata_testresults);

    % print json closing character and close log file
    fprintf(jh,'}');
    fclose(jh);
    info('* End writing JSON data file.');

    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % HTML report file generation
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    info('* Writing HTML report file..');
    hh = fopen(htmlfile,'w');
    fprintf( hh, '%s\n', ...
             '<!DOCTYPE html>','<html><head>', ...
             sprintf('<title>Report #%s</title>',job_id), ...
             '<style type="text/css">', ...
             'body {font-family: Arial, Helvetica, sans-serif;', ...
             'text-align:center; margin: 0;}', ...
             '#content {display:inline-block; text-align:left;', ...
             'box-shadow: 0 0 30px #ccc; margin: 0; padding: 2em;}', ...
             'table { border-collapse:collapse;}', ...
             'td {padding: 0.1em 0.5em;}', ...
             'thead td {text-align:center; padding: 0.5em;', ...
             'font-weight: bold;}', ...
             '.center {text-align:center;}', ...
             '.right {text-align:right;}', ...
             '.oddtr { background-color: #eee; }', ...
             '.do {margin: 0; padding: 1.5em; background-color: #afc;', ...
             'display:inline-block; border-radius:1em;', ...
             'text-decoration:none; }', ...
             'td { margin:0; border-spacing: 0;}', ...
             'blockquote { font-style: italic; }', ...
             '</style>', ...
             '<script type="text/javascript">', ...
             '');
    info('* Embedding JSON data file..');
    orig_json = loadjson(jsonfile);
    fprintf( hh, 'var traindata=\n%s\n%s\n%s\n;\n', ...
             '// >>> BEGIN JSON FORMATTED DATA >>>', ...
             savejson('',orig_json), ...
             '// <<< END JSON FORMATTED DATA <<<');
    fprintf( hh, '%s\n', ...
             '</script></head>', '<body><div id="content">', ...
             sprintf('<h1>Report #%s</h1>',job_id), ...
             '<a class="do" href="" download>', ...
             'Download this file for later use</a>', ...
             '');
    info('* End writing HTML header.');

    % -------------------------------------------------------------------------
    % HTML report -- training information

    if do_train
        info('* Writing training information...');
        fprintf( hh, '%s\n', '<blockquote>', ...
                 'Tip: You can use this file as a pre-trained model', ...
                 'for testing another dataset.', ...
                 '</blockquote>');
        fprintf( hh, '%s\n', '<h2>Training information</h2>', ...
                 '<h3>Generated problem</h3>', '<ul>', ...
                 sprintf('<li>%g positive samples</li>', ...
                         sum(trainproblem.trainlabels>0)), ...
                 sprintf('<li>%g negative samples</li>', ...
                         sum(trainproblem.trainlabels<0)), ...
                 sprintf('<li>%g partitions</li>', ...
                         size(trainproblem.partitions.train,2)), ...
                 sprintf('<li>%g avg training samples per partition</li>', ...
                         mean(sum(trainproblem.partitions.train,1))), ...
                 sprintf('<li>%g avg validation samples per partition</li>', ...
                         mean(sum(trainproblem.partitions.validation,1))), ...
                 '</ul>', ...
                 '' );
        fprintf( hh, '%s\n', ...
                 '<h3>Training process</h3>', '<ul>', ...
                 sprintf('<li>Model selection method call:<pre>%s</pre></li>', ...
                         ['select_model(problem,',features, ...
                          ',''', classifier, ''',''', method, ''')']), ...
                 sprintf('<li>Training function: <pre>%s</pre></li>', ...
                         trainmodel.trainfunc), ...
                 '<li>Training function arguments:<pre>', ...
                 savejson('',trainmodel.trainfuncargs), ...
                 '</pre></li>', ...
                 sprintf('<li>Testing function: <pre>%s</pre></li>', ...
                         trainmodel.classfunc), ...
                 sprintf('<li>Feature vector length: %g</li>', ...
                         numel(trainmodel.features)), ...
                 '</ul>', ...
                 '');

        if strfind(classifier,'mlp')
            fprintf( hh, '%s\n', ...
                     '<h3>MLP trained model</h3>', ...
                     '<blockquote>', ...
                     sprintf( ['Showing Matlab output for first ', ...
                               'out of %g trained networks'], ...
                              numel(trainmodel.trainedmodel)), ...
                     '</blockquote><pre>', ...
                     evalc('trainmodel.trainedmodel{1}'), ...
                     '</pre>', ...
                     '');
        else
            fprintf( hh, '%s\n', ...
                     '<h3>SVM trained model</h3>', '<ul>', ...
                     sprintf('<li>%g support vectors</li>', ...
                             trainmodel.trainedmodel.nsv_), ...
                     sprintf('<li>%g positive support vectors</li>', ...
                             sum(trainmodel.trainedmodel.svclass_>0)), ...
                     sprintf('<li>%g negative support vectors</li>', ...
                             sum(trainmodel.trainedmodel.svclass_<0)), ...
                     sprintf('<li>%g bounded support vectors</li>', ...
                             trainmodel.trainedmodel.nbsv_), ...
                     sprintf('<li>sum( &alpha; ) = %g</li>', ...
                             sum(trainmodel.trainedmodel.alpha_)), ...
                     sprintf('<li>bias = %g</li>', ...
                             trainmodel.trainedmodel.bias_), ...
                     sprintf('<li>C = %g</li>', ...
                             trainmodel.trainedmodel.C_), ...
                     sprintf('<li>kernel function:<pre>%s</pre></li>', ...
                             trainmodel.trainedmodel.kfunc_), ...
                     sprintf('<li>kernel parameter = %g</li>', ...
                             trainmodel.trainedmodel.kparam_), ...
                     sprintf('<li>SVM library: %s</li>', ...
                             trainmodel.trainedmodel.lib_), ...
                     '</ul>', ...
                     '');
        end
    end

    % -------------------------------------------------------------------------
    % HTML report -- testing information

    if do_test
        info('* Writing testing information...');
        fprintf( hh, '%s\n', ...
                 '<h2>Classification results</h2>', ...
                 '<table><thead><tr><td>#</td><td>identifier</td>', ...
                 '<td>sequence/secondary structure</td>', ...
                 '<td>predicted class</td>', ...
                 '</tr></thead><tbody>', ...
                 '');

        addpath('./feats');
        fastainfo = load_fasta(test_set);
        info('* Read FASTA info struct.');
        fidx = [];
        fidx([fastainfo(:).beginline])=1:numel(fastainfo);

        for j=1:numel(testresults.predict)
            fi = fidx(testproblem.testids(j,1));
            cssclass=''; if mod(j,2), cssclass='oddtr'; end
            fprintf( hh, '%s\n', ...
                     sprintf('<tr class="%s"><td>%g</td>',cssclass,j), ...
                     sprintf('<td>%s</td>',fastainfo(fi).id), ...
                     sprintf('<td class="center"><pre>%s\n%s</pre></td>', ...
                             fastainfo(fi).sequence,fastainfo(fi).structure), ...
                     sprintf('<td class="center">%g</td>',testresults.predict(j)), ...
                     '</tr>', ...
                     '');
        end
        fprintf(hh,'</tbody></table>');
    end

    info('* End of log, finishing HTML file...');
    fprintf(hh, '%s\n', '<h2>Program output</h2>', '<pre>');

    % write program output into HTML file line-by-line
    fclose(lh); lh = fopen(logfile); lc = 0;
    while ~feof(lh), lc = lc+1;
        if lc > 6, fprintf(hh, '%s\n', fgetl(lh)); end
    end
    fclose(lh);

    fprintf(hh, '%s\n', '</pre>', '</div>', '</body>', '</html>');
    fclose(hh);

    delete(logfile);
    delete(jsonfile);
    out = htmlfile;

    catch e
        info('ERROR!!! %s: %s', e.identifier, e.message);
        fclose(lh);
    end
end
