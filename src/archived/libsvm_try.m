function libsvm_try(dataset)

    addpath('/home/mauro/code/libsvm-3.12/matlab/');
    which('svmtrain')

    [train test] = load_data( dataset, 289821987, true);

    libsvmwrite( ['tmp_' dataset '_train.svm'], ...
                 [train.real(:,67);train.pseudo(:,67)], ...
                 sparse([train.real(:,1:66);train.pseudo(:,1:66)]) );

    for i=1:length(test)
        libsvmwrite( ['tmp_' test(i).name '_test.svm'], ...
                     ones(size(test(i).data(:,1)))*test(i).class, ...
                     sparse(test(i).data(:,1:66)) );
    end
    
    system( [ 'svm-scale -s tmp_' dataset '_scale tmp_' dataset '_train.svm > tmp_' dataset '_train.scaled' ] )
    for i=1:length(test)
        system( ['svm-scale -r tmp_' dataset '_scale tmp_' test(i).name '_test.svm > tmp_' test(i).name '_test.scaled'] );
    end

    libpath = getenv('LD_LIBRARY_PATH');
    if length(strfind(libpath, '/usr/lib/x86_64-linux-gnu'))<1
        libpath = ['/usr/lib/x86_64-linux-gnu:' libpath]
        setenv('LD_LIBRARY_PATH', libpath)
        !echo $LD_LIBRARY_PATH
    end
    
    system( [ 'svm-easy tmp_' dataset '_train.scaled' ] )
    
    for i=1:length(test)
        fprintf(['svm-predict tmp_' test(i).name '_test.scaled ...\n']);
        system( ['svm-predict tmp_' test(i).name '_test.scaled tmp_' dataset '_train.scaled.model tmp_ignore'] );
    end
