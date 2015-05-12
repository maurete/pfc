function setup
% Installation script

    currentdir = pwd;
    libsvm_url = ['http://www.csie.ntu.edu.tw/~cjlin/cgi-bin/libsvm.cgi?',...
                  '+http://www.csie.ntu.edu.tw/~cjlin/libsvm+zip'];
    libsvm_dir = [];

    for i=1:10
        fprintf('Searching for libSVM installation directory... ')
        aux = ls('.'); aux = textscan(aux,'%s','delimiter','\t'); aux = aux{1};
        idx = strncmpi(aux,'libsvm',6);
        for j=1:numel(idx)
            if idx(j) && isdir(aux{j}) && exist([aux{j},'/svm.cpp'])
                libsvm_dir = aux{j};
                break
            end
        end

        if numel(libsvm_dir) > 0
            fprintf('found: %s\n',libsvm_dir)
            try
                fprintf('Searching for compiled MEX files in %s... ',[libsvm_dir,'/matlab/'])
                ls([libsvm_dir,'/matlab/*.mex*']);
                fprintf('Found!\n')
            catch e
                fprintf('Not found.\n')
                fprintf('Trying to compile libsvm MEX files... \n')
                try
                    cd([libsvm_dir,'/matlab/']);
                    make
                    fprintf('Sucess! libSVM is now available and ready for use.\n')
                    cd(currentdir)
                    return
                catch ex
                    fprintf('Fail! Please make sure the C++ compiler is available.\n')
                    fprintf(['Further information on compiling libSVM Matlab interface\n',...
                             ' can be found at %s/matlab/README.\n'], libsvm_dir)
                    cd(currentdir)
                    return
                end
            end
        else
            fprintf('not found!\n')
            fprintf('Attempting to download libSVM... ')
            urlwrite(libsvm_url,'libsvm.zip');
            if exist('libsvm.zip') == 2
                fprintf('Success!\n');
                unzip('libsvm.zip');
                continue
            else fprintf(['Fail!\n', ...
                          ' Please check your connectivity, or manually download ', ...
                          'and extract libsvm to the current directory.\n'])
                break
            end
        end
    end

    fprintf('Sorry, something has gone wrong. Please verify your environment.\n')
end