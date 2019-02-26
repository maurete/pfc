function setup
%SETUP Installation script for required libraries
%

    function [mexok,idir] = vdep(prefix,indfile,mexdir,mexnames)
    % function for finding installation directory of dependencies:
    % prefix = directory name should match this prefix
    % indfile = indicator file - should be found inside directory
    % mexdir = sub-directory where to look for .mex* files
    % mexnames = name of required .mex* files
    % (ret) mexok = all required .mex files are available
    % (ret) idir = found installation directory

        % Set missing parameters
        if nargin < 4 || isempty(mexnames); mexnames  = {}; end
        if nargin < 3 || isempty(mexdir);   mexdir = '.';   end

        idir  = [];
        mexok = false(1,numel(mexnames));

        % find install dir by matching prefix for all directories
        aux = dir('.'); aux = {aux.name};
        idx = strncmpi(aux,prefix,numel(prefix));
        for j=1:numel(idx)
            % look for indicator file if given, else just match prefix
            if idx(j) && isdir(aux{j}) && (isempty(indfile) || ...
                                           exist([aux{j},'/',indfile]))
                idir = aux{j};
                break
            end
        end

        % now check for .mex* files
        if ~isempty(idir)
            for i=1:numel(mexnames)
                fname = sprintf('%s/%s/%s.%s',idir,mexdir,mexnames{i},mexext);
                % octave -> |5-3|=2, matlab -> |0-2|=2
                if abs(exist('OCTAVE_VERSION', 'builtin') - exist(fname)) == 2
                    mexok(i) = 1;
                end
            end
        end

        mexok = all(mexok);
    end

    % default URLs

    libsvm_url  = 'https://github.com/cjlin1/libsvm/archive/v323.zip';
    jsonlab_url = 'https://github.com/fangq/jsonlab/archive/master.zip';
    mfann_url   = 'https://github.com/dgorissen/mfann/archive/master.zip';
    called_compile = false;

    % helper functions based on vdep
    function[o,d]=check_libsvm,[o,d]=vdep('libsvm','svm.cpp','matlab', ...
        {'libsvmread','libsvmwrite','svmpredict','svmtrain'});end
    function[o,d]=check_jsonlab,[o,d]=vdep('jsonlab','loadjson.m',[],{});end
    function[o,d]=check_fann,[o,d]=vdep('mfann','createFann.c','', ...
        {'createFann','testFann','trainFann'});end


    % verify libSVM installation ----------------------------------------------

    fprintf('Checking libSVM installation... ')
    [libsvm_ok,libsvm_dir] = check_libsvm;

    if libsvm_ok, fprintf('OK.\n');
    else, fprintf('Error!\n');
        if isempty(libsvm_dir)
            % libsvm_dir not found
            if exist('libsvm.zip') ~= 2
                % libsvm.zip not found, download it
                fprintf('Downloading libSVM... ')
                system(['./download.sh "' libsvm_url '" libsvm.zip']);
                if ans==0, fprintf('OK.\n'); else, fprintf('Error!\n'); end
            end
            if exist('libsvm.zip') == 2
                % libsvm.zip exists, unzip it
                fprintf('Extracting libsvm.zip.. \n');
                unzip('libsvm.zip');
                % guess just-extracted libsvm dir name
                [~,libsvm_dir] = check_libsvm;
            else
                % print error message and exit
                fprintf([ ...
                    'ERROR: libsvm.zip file not found.\n', ...
                    'Please download %s \n', ...
                    'and save it as libsvm.zip in the current directory,\n', ...
                    'then try running this script again.', ...
                        ], libsvm_url);
                return;
            end
        end

        assert(~isempty(libsvm_dir),sprintf([ ...
            'libsvm.zip has incorrect structure, please delete libsvm.zip', ...
            ' and (optionally) download it from %s\n'], libsvm_url));

        fprintf('Compiling libsvm MEX files... \n')
        % Try compiling libSVM from source
        called_compile = true;
        currentdir = pwd;
        cd(fullfile(libsvm_dir,'matlab'))
        make
        cd(currentdir);

        % check if files compiled OK
        [libsvm_ok,~] = check_libsvm;
    end

    % save libsvm directory in config.m
    if libsvm_ok,setconfig('LIBSVM_DIR',['./',libsvm_dir,'/matlab/']);end


    % verify jsonlab installation ---------------------------------------------

    fprintf('Checking jsonlab installation... ')
    [~,jsonlab_dir] = check_jsonlab;

    if ~isempty(jsonlab_dir), fprintf('OK.\n');
    else, sprintf('Error!\n');
        if isempty(jsonlab_dir)
            fprintf('Downloading jsonlab... ')
            system(['./download.sh "' jsonlab_url '" jsonlab.zip']);
            if ans==0, fprintf('OK.\n'); else, fprintf('Error!\n'); end
            if exist('jsonlab.zip') == 2
                fprintf('Extracting jsonlab.zip... \n');
                unzip('jsonlab.zip');
                % guess just-extracted jsonlab dir name
                [~,jsonlab_dir] = check_jsonlab;
            else
                % print error message and exit
                fprintf([ ...
                    'ERROR: jsonlab.zip file not found.\n', ...
                    'Please download %s \n', ...
                    'and save it as jsonlab.zip in the current directory,\n', ...
                    'then try running this script again.', ...
                        ], jsonlab_url);
                return;
            end
        end
    end

    if isempty(jsonlab_dir),
        sprintf([ ...
            'jsonlab.zip has incorrect structure, please remove it',...
            ' and (optionally) download it from %s\n', ...
            'JSONlab is required for using the web interface.\n'], ...
                jsonlab_url);
    else
        setconfig('JSONLAB_DIR',['./',jsonlab_dir,'/']);
    end

    % verify libFANN installation ---------------------------------------------

    fprintf('Checking libFANN Matlab bindings installation... ')
    [fann_ok,fann_dir] = check_fann;

    if fann_ok, fprintf('OK.\n');
    else,
        fprintf('Error!\n');
        if isempty(fann_dir)
            fprintf('Downloading libFANN Matlab bindings... ')
            system(['./download.sh "' mfann_url '" mfann.zip']);
            if ans==0, fprintf('OK.\n'); else, fprintf('Error!\n'); end
            if exist('mfann.zip') == 2
                fprintf('Extracting mfann.zip...\n');
                unzip('mfann.zip');
                % guess just-extracted mfann dir name
                [~,fann_dir] = check_fann;
            else
                % print error message and keep going
                fprintf([ ...
                    'ERROR: mfann.zip file not found.\n', ...
                    'Please download %s \n', ...
                    'and save it as mfann.zip, ', ...
                    'then try running this script again to enable ',...
                    'libFANN support.\n', ...
                    'Please note that libFANN is not required ',...
                    'on MATLAB installations.\n', ...
                        ], mfann_url);
            end
        end

        if ~isempty(fann_dir)

            fprintf('Compiling mfann MEX files... \n')
            called_compile = true;

            % compile FANN .mex files
            currentdir = pwd;
            cd(fullfile(fann_dir))
            % setenv('MATLABDIR',matlabroot)
            % system('make');
            system('sed -i "s/#/=/g" makeFann.m');
            try,makeFann,end
            cd(currentdir);

            [fann_ok,~] = check_fann;
        end
    end

    % save mfann directory in config.m
    if fann_ok,setconfig('FANN_DIR',['./',fann_dir,'/']);end


    % sample data directory ---------------------------------------------------

    % TODO: do actual verification of data directory before setting this
    setconfig('SAMPLE_DATA_DIR','../data');


    % web run directory -------------------------------------------------------

    % do not change value if already present
    setconfig('WEB_WORK_DIR','./run',true,false);


    % rnafold external command ------------------------------------------------

    fprintf(['Checking availability of RNAfold program... '])
    ret = system('RNAfold < /dev/null');
    if ret == 0
        fprintf('OK.\n')
        % guess noPS switch correct syntax
        if system('RNAfold -noPS < /dev/null') == 0
            setconfig('RNAFOLD_EXT_CMD','RNAfold -noPS');
        elseif system('RNAfold -noPS < /dev/null') == 0
            setconfig('RNAFOLD_EXT_CMD','RNAfold --noPS');
        end
    else
        fprintf(['not found!\n', ...
                 'We recommend installing the Vienna RNA package\n', ...
                 'from https://www.tbi.univie.ac.at/RNA/ and making\n', ...
                 'the RNAfold command available in your PATH.\n', ...
                ])
    end

    if any([called_compile, ~libsvm_ok, ~fann_ok])
        fprintf([ ...,
            'Please check above output for any errors.\n', ...
            'In most cases, compilation errors can be fixed \n', ...
            'by installing appropiate tools and dependencies: \n', ...
            'make, gcc, g++, libsvm-dev, and libfann-dev. \n', ...
                ])
    end

    if libsvm_ok
        fprintf('\nSuccessfully verified installation.\n')
    end

end
