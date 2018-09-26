function setup
%SETUP Installation script for required libraries
%

% libsvm_url  = 'https://github.com/cjlin1/libsvm/archive/v318.zip';
    libsvm_url  = 'https://github.com/cjlin1/libsvm/archive/v323.zip';
    jsonlab_url = 'https://github.com/fangq/jsonlab/archive/master.zip';
    libfann_url = 'https://github.com/libfann/fann/archive/2.2.0.zip';
    mfann_url   = 'https://github.com/dgorissen/mfann/archive/master.zip';

    function [res,libsvm_dir] = check_libsvm
        libsvm_dir = '';
        mexfiles = {'libsvmread','libsvmwrite','svmpredict','svmtrain'};
        found_mex = false(1,4);
        % Find libSVM installation directory
        % Search for directories with name beginning in 'libsvm'
        aux = textscan(ls('.','-1'),'%s'); aux = aux{1};
        idx = strncmpi(aux,'libsvm',6);
        for j=1:numel(idx)
            % Guess svmdir looking for 'svm.cpp' file
            if idx(j) && isdir(aux{j}) && exist([aux{j},'/svm.cpp'])
                libsvm_dir = aux{j}
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
        aux = textscan(ls('.','-1'),'%s'); aux = aux{1};
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

    function [res,fann_dir] = check_fann
        fann_dir = '';
        mexfiles = {'createFann', 'trainFann', 'testFann'};
        found_mex = false(1,numel(mexfiles));
        % Find FANN Matlab bindings installation directory
        % Search for directories with name beginning in 'mfann'
        aux = textscan(ls('.','-1'),'%s'); aux = aux{1};
        idx = strncmpi(aux,'mfann',5);
        for j=1:numel(idx)
            if idx(j) && isdir(aux{j}), fann_dir = aux{j}; break, end
        end
        % Find FANN binding .mex compiled files
        for i=1:numel(mexfiles)
            if exist(sprintf('%s/%s.%s',fann_dir,mexfiles{i},mexext)) == 2
                found_mex(i) = 1;
            end
        end
        res = all(found_mex);
        if ~res, fann_dir = ''; end
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
                fprintf(['Fail!\n', 'Please check your connectivity, or ', ...
                         'manually download libsvm into current directory.\n']);
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
                fprintf(['Fail!\n', 'Please check your connectivity, or ', ...
                         'manually download jsonlab into current directory.\n']);
            end
        end
    end

    % Find fann installation directory
    fprintf('Checking libFANN Matlab bindings installation... ')
    [fann_ok, fann_dir] = check_fann;

    if fann_ok, fprintf('OK.\n');
    else,
        fprintf('Error!\n');
        if isempty(fann_dir)
            fprintf('Attempting to download libFANN Matlab bindings... ')
            urlwrite(mfann_url,'mfann.zip');
            if exist('mfann.zip') == 2
                fprintf('Success!\n');
                unzip('mfann.zip');
            else
                fprintf(['Fail!\n']);
            end
        end
        fprintf('\nThis script is not smart enough for setting up libFANN \n')
        fprintf('bindings. To do it yourself, please install libfann in \n')
        fprintf('in your system (sudo apt-get install libfann-dev), then \n')
        fprintf('download libfann Matlab bindings into a directory named \n')
        fprintf('''mfann'', and finally compile required .mex files by \n')
        fprintf('running ''make'' in a shell in the ''mfann'' directory.\n')
        fprintf('\nlibfann Matlab bindings can be downloaded from:\n%s\n', ...
                mfann_url)
        fprintf('Please also note also that libfann is not required for \n')
        fprintf('using the software if the Neural Net Toolbox is available.\n')
    end

    [mex_ok, libsvm_dir] = check_libsvm;
    [m_ok, jsonlab_dir] = check_jsonlab;

    if mex_ok && m_ok
        fprintf('\nSuccessfully verified installation.\n')
        fprintf('Be sure to set the following in your config.m file:\n\n')

        fprintf('LIBSVM_DIR=''./%s/matlab/'';\n',libsvm_dir)
        fprintf('JSONLAB_DIR=''./%s/'';\n',jsonlab_dir)
        if fann_dir, fprintf('FANN_DIR=''./%s/'';\n',fann_dir), end
    else
        fprintf('\n\nAn error occurred setting up required packages.')
        fprintf('Please check above output.')
    end

end
