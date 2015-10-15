function gen_shark_data(dataset, featset, npart)


    dataname = [dataset, int2str(featset), '.data'];
    if exist(dataname,'file') == 2
        fprintf('file %s already exists, aborting!\n')
        return
    end

    com = common;
    [train test] = load_data(dataset,27614);
    traindata = com.stshuffle(874198,[train.real; train.pseudo]);
    %[part.train part.validation] = stpart(randseed, traindata, npart, ratio);

    labels = traindata(:,67);
    entries = traindata(:,com.featindex{featset});

    fprintf('writing data to %s...\n', dataname);
    fh = fopen(dataname,'w');
    fprintf(fh, '# %d %d 1 ascii\n', size(entries,1), size(entries,2));
    for i=1:size(entries,1)
        fprintf(fh, '%f ', entries(i,:));
        fprintf(fh, '%d\n', labels(i));
    end
    fclose(fh);

    fprintf('generating %d partitions...\n', npart);
    [ti vi] = stpart(3491824, size(entries,1), npart, 0.15);
    ntrain = size(ti,1);
    nval = size(vi,1);
    for p=1:npart
        partname = [dataset, int2str(featset), '-', int2str(p-1), '.split'];
        fh = fopen(partname,'w');
        fprintf(fh, '# %d %d\n', ntrain, nval);
        fprintf(fh, '%d\n', ti(:,p)-1);
        fprintf(fh, '%d\n', vi(:,p)-1);
        fclose(fh);
    end

end