function all_tests

    ds = { 'ng-multi', 'batuwita-multi', 'xue', 'ng', 'batuwita'};
    rn = [303456; 456789; 5829]; 

    fprintf('\n >>>>> Running all single-loop tests ...\n')
    for j=3:5
        for i=1:15
            fprintf('\n >>>>>>>> dataset %s, featset %d ....\n', ds{j}, i)
            svm_lin(ds{j},i,rn)
            svm_rbf(ds{j},i,rn)
            mlp(ds{j},i,0,rn)
            mlp(ds{j},i,1,rn)
        end
    end

    fprintf('\n >>>>> Running all multi-loop tests ...\n')
    for j=1:2
        for i=[4 5 8]
            fprintf('\n >>>>>>>> dataset %s, featset %d ....\n', ds{j}, i)
            svm_lin(ds{j},i,rn)
            svm_rbf(ds{j},i,rn)
            mlp(ds{j},i,0,rn)
            mlp(ds{j},i,1,rn)
        end
    end

end