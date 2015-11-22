function setup

    % Installation script for required libraries

    libsvm_url = ['http://www.csie.ntu.edu.tw/~cjlin/cgi-bin/libsvm.cgi?',...
                  '+http://www.csie.ntu.edu.tw/~cjlin/libsvm+zip'];
    jsonlab_url = 'https://github.com/fangq/jsonlab/archive/master.zip';

    function [res,libsvm_dir] = check_libsvm
        libsvm_dir = '';
        mexfiles = {'libsvmread','libsvmwrite','svmpredict','svmtrain'};
        found_mex = false(1,4);
        % Find libSVM installation directory
        % Search for directories with name beginning in 'libsvm'
        aux = ls('.'); aux = textscan(aux,'%s','delimiter','\t'); aux = aux{1};
        idx = strncmpi(aux,'libsvm',6);
        for j=1:numel(idx)
            % Guess svmdir looking for 'svm.cpp' file
            if idx(j) && isdir(aux{j}) && exist([aux{j},'/svm.cpp'])
                libsvm_dir = aux{j};
                break
            end
        end
        % Find libsvm's .mex compiled files
        for i=1:4
            if exist(sprintf('%s/matlab/%s.%s',libsvm_dir, ...
                             mexfiles{i},mexext)) == 2
                found_mex(i) = 1;
            end
        end
        res = all(found_mex);
    end

    function err = make_libsvm(libsvm_dir)
        % Copied from libsvm's own make.m
        err = true;
        currentdir = pwd;
        cd(fullfile(libsvm_dir,'matlab'))
        try
            % Octave
            Type = ver;
            if(strcmp(Type(1).Name, 'Octave') == 1)
		mex libsvmread.c
		mex libsvmwrite.c
		mex svmtrain.c ../svm.cpp svm_model_matlab.c
		mex svmpredict.c ../svm.cpp svm_model_matlab.c
            else
                % MATLAB: Add -largeArrayDims on 64-bit machines
		mex CFLAGS="\$CFLAGS -std=c99" -largeArrayDims libsvmread.c
		mex CFLAGS="\$CFLAGS -std=c99" -largeArrayDims libsvmwrite.c
		mex CFLAGS="\$CFLAGS -std=c99" -largeArrayDims svmtrain.c ../svm.cpp svm_model_matlab.c
		mex CFLAGS="\$CFLAGS -std=c99" -largeArrayDims svmpredict.c ../svm.cpp svm_model_matlab.c
            end
            err = false;
        catch
        end
        cd(currentdir);
    end

    function [res,jsonlab_dir] = check_jsonlab
        jsonlab_dir = '';
        mfiles = {'jsonopt','loadjson','mergestruct','savejson',...
                  'struct2jdata','varargin2struct'};
        found_m = false(1,numel(mfiles));
        % Find jsonlab installation directory
        % Search for directories with name beginning in 'jsonlab'
        aux = ls('.'); aux = textscan(aux,'%s','delimiter','\t'); aux = aux{1};
        idx = strncmpi(aux,'jsonlab',7);
        for j=1:numel(idx)
            if idx(j) && isdir(aux{j}), jsonlab_dir = aux{j}; break, end
        end
        % Find jsonlab .m files
        for i=1:numel(mfiles)
            if exist(sprintf('%s/%s.m',jsonlab_dir,mfiles{i})) == 2
                found_m(i) = 1;
            end
        end
        res = all(found_m);
    end

    % Find libSVM installation directory
    fprintf('Checking libSVM installation... ')
    [mex_ok, libsvm_dir] = check_libsvm;

    if mex_ok, fprintf('OK.\n');
    else, fprintf('Error!\n');
        if isempty(libsvm_dir)
            % Check if libsvm dir found, else download and extract it
            fprintf('Attempting to download libSVM... ')
            try, urlwrite(libsvm_url,'libsvm.zip'); end
            if exist('libsvm.zip') == 2
                fprintf('Success!\n');
                unzip('libsvm.zip');
            else
                fprintf(['Fail!\n', 'Please check your connectivity, ', ...
                         'or manually download libsvm into current directory.\n']);
                return;
            end
        end
        [mex_ok, libsvm_dir] = check_libsvm;
        fprintf('Trying to compile libsvm MEX files... \n')
        % Try compiling libSVM from source
        if make_libsvm(libsvm_dir)
            fprintf('Fail! Please make sure the C++ compiler is available.\n')
            fprintf(['Further information on compiling libSVM''s Matlab \n',...
                     'interface can be found at %s/matlab/README.\n'], libsvm_dir)
        end
    end

    % Find jsonlab installation directory
    fprintf('Checking jsonlab installation... ')
    [m_ok, jsonlab_dir] = check_jsonlab;

    if m_ok, fprintf('OK.\n');
    else,
        sprintf('Error!\n');
        if isempty(jsonlab_dir)
            fprintf('Attempting to download jsonlab... ')
            urlwrite(jsonlab_url,'jsonlab.zip');
            if exist('jsonlab.zip') == 2
                fprintf('Success!\n');
                unzip('jsonlab.zip');
            else
                fprintf(['Fail!\n', 'Please check your connectivity, ', ...
                         'or manually download jsonlab into current directory.\n']);
            end
        end
    end

    [mex_ok, libsvm_dir] = check_libsvm;
    [m_ok, jsonlab_dir] = check_jsonlab;

    if mex_ok && m_ok
        fprintf('\n\nSuccessfully verified installation.\n')
        fprintf('Be sure to set the following in your config.m file:\n\n')

        fprintf('LIBSVM_DIR=''./%s/matlab/'';\n',libsvm_dir)
        fprintf('JSONLAB_DIR=''./%s/'';\n',jsonlab_dir)
    else
        fprintf('\n\nAn error occurred setting up required packages.')
        fprintf('Please check above output.')
    end

end
